import { activate, disconnect, getNetworkDetails } from '@autonomys/auto-utils'
import type { ApiPromise } from '@polkadot/api'

export type NetworkId = 'chronos' | 'mainnet'

const NETWORK_TOKENS: Record<NetworkId, { symbol: string; name: string }> = {
  chronos: { symbol: 'tAI3', name: 'Testnet Auto Token' },
  mainnet: { symbol: 'AI3', name: 'Auto Token' },
}

export function resolveNetwork(flag?: string): NetworkId {
  if (flag === 'mainnet' || flag === 'chronos') return flag
  const env = process.env.AUTO_RESPAWN_NETWORK
  if (env === 'mainnet' || env === 'chronos') return env
  return 'chronos'
}

export function tokenSymbol(network: NetworkId): string {
  return NETWORK_TOKENS[network].symbol
}

export function isMainnet(network: NetworkId): boolean {
  return network === 'mainnet'
}

export async function connectApi(network: NetworkId): Promise<ApiPromise> {
  const api = await activate({ networkId: network })
  return api
}

export async function disconnectApi(api: ApiPromise): Promise<void> {
  await disconnect(api)
}
