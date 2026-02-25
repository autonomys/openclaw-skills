#!/usr/bin/env node

import { connectApi, disconnectApi, resolveNetwork, type NetworkId } from './lib/network.js'
import { createWallet, importWallet, listWallets, loadWallet } from './lib/wallet.js'
import { queryBalance } from './lib/balance.js'
import { transferTokens } from './lib/transfer.js'
import { submitRemark } from './lib/remark.js'

const COMMANDS_WITH_SUBCOMMANDS = new Set(['wallet'])

function parseArgs(argv: string[]): { command: string; subcommand?: string; flags: Record<string, string>; positional: string[] } {
  const args = argv.slice(2)
  const command = args[0] || ''
  const hasSubcommand = COMMANDS_WITH_SUBCOMMANDS.has(command)
  const subcommand = hasSubcommand && args[1] && !args[1].startsWith('--') ? args[1] : undefined
  const flags: Record<string, string> = {}
  const positional: string[] = []

  let i = subcommand ? 2 : 1
  while (i < args.length) {
    if (args[i].startsWith('--')) {
      const key = args[i].slice(2)
      const next = args[i + 1]
      if (next && !next.startsWith('--')) {
        flags[key] = next
        i += 2
      } else {
        flags[key] = 'true'
        i++
      }
    } else {
      positional.push(args[i])
      i++
    }
  }

  return { command, subcommand, flags, positional }
}

function output(data: unknown): void {
  console.log(JSON.stringify(data, null, 2))
}

function error(message: string, code = 1): never {
  console.error(JSON.stringify({ error: message }))
  process.exit(code)
}

async function handleWallet(subcommand: string | undefined, flags: Record<string, string>): Promise<void> {
  switch (subcommand) {
    case 'create': {
      const name = flags.name || 'default'
      const result = await createWallet(name)
      // Output mnemonic to stderr so it's visible to the user but separable from JSON output
      console.error('')
      console.error('=== IMPORTANT: BACKUP YOUR RECOVERY PHRASE ===')
      console.error('')
      console.error(`  ${result.mnemonic}`)
      console.error('')
      console.error('Write these 12 words down and store them securely.')
      console.error('This is the ONLY time they will be displayed.')
      console.error('Anyone with these words can access your wallet.')
      console.error('')
      console.error('===============================================')
      console.error('')
      output({ name: result.name, address: result.address, keyfilePath: result.keyfilePath })
      break
    }

    case 'import': {
      const name = flags.name
      const mnemonic = flags.mnemonic
      if (!name) error('--name is required for wallet import')
      if (!mnemonic) error('--mnemonic is required for wallet import')
      const result = await importWallet(name, mnemonic)
      output(result)
      break
    }

    case 'list': {
      const wallets = await listWallets()
      output({ wallets })
      break
    }

    default:
      error(`Unknown wallet subcommand: "${subcommand}". Use: create, import, list`)
  }
}

async function handleBalance(flags: Record<string, string>, positional: string[]): Promise<void> {
  const address = positional[0] || flags.address
  if (!address) error('Address is required. Usage: balance <address> [--network chronos|mainnet]')

  const network = resolveNetwork(flags.network)
  const api = await connectApi(network)

  try {
    const result = await queryBalance(api, address, network)
    output(result)
  } finally {
    await disconnectApi(api)
  }
}

async function handleTransfer(flags: Record<string, string>): Promise<void> {
  const from = flags.from
  const to = flags.to
  const amount = flags.amount

  if (!from) error('--from <wallet-name> is required')
  if (!to) error('--to <address> is required')
  if (!amount) error('--amount <tokens> is required')

  const network = resolveNetwork(flags.network)
  const pair = await loadWallet(from)
  const api = await connectApi(network)

  try {
    const result = await transferTokens(api, pair, to, amount, network)
    output(result)
  } finally {
    await disconnectApi(api)
  }
}

async function handleRemark(flags: Record<string, string>): Promise<void> {
  const from = flags.from
  const data = flags.data

  if (!from) error('--from <wallet-name> is required')
  if (!data) error('--data <string> is required')

  const network = resolveNetwork(flags.network)
  const pair = await loadWallet(from)
  const api = await connectApi(network)

  try {
    const result = await submitRemark(api, pair, data, network)
    output(result)
  } finally {
    await disconnectApi(api)
  }
}

function printUsage(): void {
  console.error(`auto-respawn — Anchor agent identity on the Autonomys Network

Commands:
  wallet create [--name <name>]                          Create a new wallet
  wallet import --name <name> --mnemonic "<words>"       Import from recovery phrase
  wallet list                                            List saved wallets

  balance <address> [--network chronos|mainnet]          Check wallet balance

  transfer --from <wallet> --to <address> --amount <n>   Transfer tokens
           [--network chronos|mainnet]

  remark --from <wallet> --data <string>                 Write on-chain remark
         [--network chronos|mainnet]

Environment:
  AUTO_RESPAWN_PASSPHRASE       Wallet encryption passphrase
  AUTO_RESPAWN_PASSPHRASE_FILE  Path to passphrase file
  AUTO_RESPAWN_NETWORK          Default network (chronos|mainnet)`)
}

async function main(): Promise<void> {
  const { command, subcommand, flags, positional } = parseArgs(process.argv)

  try {
    switch (command) {
      case 'wallet':
        await handleWallet(subcommand, flags)
        break
      case 'balance':
        await handleBalance(flags, positional)
        break
      case 'transfer':
        await handleTransfer(flags)
        break
      case 'remark':
        await handleRemark(flags)
        break
      case 'help':
      case '--help':
      case '-h':
      case '':
        printUsage()
        break
      default:
        error(`Unknown command: "${command}". Run with --help for usage.`)
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    error(message)
  }
}

// Catch unhandled rejections (e.g. from Polkadot RPC errors)
process.on('unhandledRejection', (err) => {
  const message = err instanceof Error ? err.message : String(err)
  error(message)
})

main()
