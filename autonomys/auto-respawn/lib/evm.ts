import { ethers } from 'ethers'
import { getNetworkDomainRpcUrls } from '@autonomys/auto-utils'
import type { NetworkId } from './network.js'

/** Auto-EVM domain ID on Autonomys */
const EVM_DOMAIN_ID = '0'

/**
 * Default MemoryChain contract address.
 * Override with AUTO_RESPAWN_CONTRACT_ADDRESS env var if your deployment differs.
 */
export const MEMORY_CHAIN_ADDRESS_DEFAULT = '0x51DAedAFfFf631820a4650a773096A69cB199A3c'

export function getMemoryChainAddress(): string {
  return process.env.AUTO_RESPAWN_CONTRACT_ADDRESS || MEMORY_CHAIN_ADDRESS_DEFAULT
}

/**
 * MemoryChain contract ABI — matches the official ABI from
 * auto-sdk/packages/auto-agents/src/experiences/abi/memory.ts
 */
export const MEMORY_CHAIN_ABI = [
  {
    inputs: [{ internalType: 'bytes32', name: 'hash', type: 'bytes32' }],
    name: 'setLastMemoryHash',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ internalType: 'address', name: '_agent', type: 'address' }],
    name: 'getLastMemoryHash',
    outputs: [{ internalType: 'bytes32', name: '', type: 'bytes32' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ internalType: 'address', name: '', type: 'address' }],
    name: 'lastMemoryHash',
    outputs: [{ internalType: 'bytes32', name: '', type: 'bytes32' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: 'address', name: 'agent', type: 'address' },
      { indexed: false, internalType: 'bytes32', name: 'hash', type: 'bytes32' },
    ],
    name: 'LastMemoryHashSet',
    type: 'event',
  },
] as const

/**
 * Get the Auto-EVM WebSocket RPC URL for a given network.
 */
export function getEvmRpcUrl(network: NetworkId): string {
  const urls = getNetworkDomainRpcUrls({ networkId: network, domainId: EVM_DOMAIN_ID })
  if (!urls || urls.length === 0) {
    throw new Error(`No Auto-EVM RPC URL found for network "${network}"`)
  }
  return urls[0]
}

/**
 * Connect to Auto-EVM and return an ethers provider.
 */
export function connectEvmProvider(network: NetworkId): ethers.WebSocketProvider {
  const url = getEvmRpcUrl(network)
  return new ethers.WebSocketProvider(url)
}

/**
 * Derive an EVM private key + address from a BIP39 mnemonic.
 * Uses standard BIP44 derivation path m/44'/60'/0'/0/0 (MetaMask-compatible).
 */
export function deriveEvmKey(mnemonic: string): { privateKey: string; address: string } {
  const mnemonicObj = ethers.Mnemonic.fromPhrase(mnemonic)
  const hdWallet = ethers.HDNodeWallet.fromMnemonic(mnemonicObj, "m/44'/60'/0'/0/0")
  return {
    privateKey: hdWallet.privateKey,
    address: hdWallet.address,
  }
}

/**
 * Create an ethers Wallet (signer) from an EVM private key + provider.
 */
export function createEvmSigner(privateKey: string, provider: ethers.Provider): ethers.Wallet {
  return new ethers.Wallet(privateKey, provider)
}

/**
 * Get a MemoryChain contract instance.
 * Pass a signer for write operations (anchor), or a provider for read-only (gethead).
 */
export function getMemoryChainContract(
  signerOrProvider: ethers.Wallet | ethers.Provider,
): ethers.Contract {
  const address = getMemoryChainAddress()
  return new ethers.Contract(address, MEMORY_CHAIN_ABI, signerOrProvider)
}
