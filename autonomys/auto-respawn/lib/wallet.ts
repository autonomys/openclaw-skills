import { readdir, readFile, writeFile, mkdir } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { createInterface } from 'node:readline'
import {
  Keyring,
  cryptoWaitReady,
  generateWallet as sdkGenerateWallet,
  setupWallet as sdkSetupWallet,
  address as formatAddress,
} from '@autonomys/auto-utils'
import type { KeyringPair, KeyringPair$Json } from '@polkadot/keyring/types'

const WALLETS_DIR = join(
  process.env.HOME || process.env.USERPROFILE || '~',
  '.openclaw',
  'auto-respawn',
  'wallets',
)

const PASSPHRASE_FILE_DEFAULT = join(
  process.env.HOME || process.env.USERPROFILE || '~',
  '.openclaw',
  'auto-respawn',
  '.passphrase',
)

export interface WalletInfo {
  name: string
  address: string
  keyfilePath: string
}

export interface CreatedWallet extends WalletInfo {
  mnemonic: string
}

async function ensureWalletsDir(): Promise<void> {
  if (!existsSync(WALLETS_DIR)) {
    await mkdir(WALLETS_DIR, { recursive: true, mode: 0o700 })
  }
}

function keyfilePath(name: string): string {
  return join(WALLETS_DIR, `${name}.json`)
}

export async function resolvePassphrase(): Promise<string> {
  // 1. Environment variable
  const envPassphrase = process.env.AUTO_RESPAWN_PASSPHRASE
  if (envPassphrase) return envPassphrase

  // 2. Passphrase file
  const passphraseFilePath =
    process.env.AUTO_RESPAWN_PASSPHRASE_FILE || PASSPHRASE_FILE_DEFAULT
  try {
    const contents = await readFile(passphraseFilePath, 'utf-8')
    const trimmed = contents.trim()
    if (trimmed) return trimmed
  } catch {
    // File doesn't exist or can't be read — fall through
  }

  // 3. Interactive stdin prompt
  if (process.stdin.isTTY) {
    return new Promise<string>((resolve, reject) => {
      const rl = createInterface({ input: process.stdin, output: process.stderr })
      rl.question('Passphrase: ', (answer) => {
        rl.close()
        if (!answer) reject(new Error('No passphrase provided'))
        else resolve(answer)
      })
    })
  }

  throw new Error(
    'No passphrase found. Set AUTO_RESPAWN_PASSPHRASE env var, ' +
      'write it to ~/.openclaw/auto-respawn/.passphrase, ' +
      'or run interactively.',
  )
}

export async function createWallet(name: string): Promise<CreatedWallet> {
  await cryptoWaitReady()
  await ensureWalletsDir()

  const filepath = keyfilePath(name)
  if (existsSync(filepath)) {
    throw new Error(`Wallet "${name}" already exists at ${filepath}`)
  }

  const wallet = sdkGenerateWallet()
  if (!wallet.keyringPair) throw new Error('Failed to generate wallet keypair')
  const passphrase = await resolvePassphrase()
  const json = wallet.keyringPair.toJson(passphrase)

  // Add name to metadata
  json.meta = { ...json.meta, name, whenCreated: Date.now() }

  await writeFile(filepath, JSON.stringify(json, null, 2), { mode: 0o600 })

  return {
    name,
    address: wallet.address,
    mnemonic: wallet.mnemonic,
    keyfilePath: filepath,
  }
}

export async function importWallet(name: string, mnemonic: string): Promise<WalletInfo> {
  await cryptoWaitReady()
  await ensureWalletsDir()

  const filepath = keyfilePath(name)
  if (existsSync(filepath)) {
    throw new Error(`Wallet "${name}" already exists at ${filepath}`)
  }

  const wallet = sdkSetupWallet({ mnemonic })
  if (!wallet.keyringPair) throw new Error('Failed to setup wallet keypair from mnemonic')
  const passphrase = await resolvePassphrase()
  const json = wallet.keyringPair.toJson(passphrase)

  json.meta = { ...json.meta, name, whenCreated: Date.now() }

  await writeFile(filepath, JSON.stringify(json, null, 2), { mode: 0o600 })

  return {
    name,
    address: wallet.address,
    keyfilePath: filepath,
  }
}

export async function listWallets(): Promise<WalletInfo[]> {
  await cryptoWaitReady()

  if (!existsSync(WALLETS_DIR)) return []

  const files = await readdir(WALLETS_DIR)
  const wallets: WalletInfo[] = []

  for (const file of files) {
    if (!file.endsWith('.json')) continue
    try {
      const filepath = join(WALLETS_DIR, file)
      const raw = await readFile(filepath, 'utf-8')
      const json: KeyringPair$Json = JSON.parse(raw)
      const name = (json.meta?.name as string) || file.replace('.json', '')
      // Convert the generic SS58 address to Autonomys format
      const autonomysAddress = formatAddress(json.address)
      wallets.push({ name, address: autonomysAddress, keyfilePath: filepath })
    } catch {
      // Skip malformed files
    }
  }

  return wallets
}

export async function loadWallet(name: string): Promise<KeyringPair> {
  await cryptoWaitReady()

  const filepath = keyfilePath(name)
  if (!existsSync(filepath)) {
    throw new Error(`Wallet "${name}" not found at ${filepath}`)
  }

  const raw = await readFile(filepath, 'utf-8')
  const json: KeyringPair$Json = JSON.parse(raw)

  const keyring = new Keyring({ type: 'sr25519' })
  const pair = keyring.addFromJson(json)

  const passphrase = await resolvePassphrase()
  try {
    pair.decodePkcs8(passphrase)
  } catch {
    throw new Error('Wrong passphrase — could not decrypt wallet')
  }

  return pair
}
