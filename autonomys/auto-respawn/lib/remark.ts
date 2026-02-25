import { remark } from '@autonomys/auto-consensus'
import { signAndSendTx, address as formatAddress } from '@autonomys/auto-utils'
import type { ApiPromise } from '@polkadot/api'
import type { KeyringPair } from '@polkadot/keyring/types'
import { type NetworkId, tokenSymbol, isMainnet } from './network.js'

export interface RemarkResult {
  success: boolean
  txHash: string | undefined
  blockHash: string | undefined
  from: string
  data: string
  network: NetworkId
  symbol: string
  warning?: string
}

export async function submitRemark(
  api: ApiPromise,
  sender: KeyringPair,
  data: string,
  network: NetworkId,
): Promise<RemarkResult> {
  const tx = remark(api, data)

  const result = await signAndSendTx(sender, tx)

  const remarkResult: RemarkResult = {
    success: result.success,
    txHash: result.txHash,
    blockHash: result.blockHash,
    from: formatAddress(sender.address),
    data,
    network,
    symbol: tokenSymbol(network),
  }

  if (isMainnet(network)) {
    remarkResult.warning = 'This was a mainnet transaction with real AI3 tokens.'
  }

  return remarkResult
}
