import { transfer, events } from '@autonomys/auto-consensus'
import { signAndSendTx, ai3ToShannons, address as formatAddress } from '@autonomys/auto-utils'
import type { ApiPromise } from '@polkadot/api'
import type { KeyringPair } from '@polkadot/keyring/types'
import { type NetworkId, tokenSymbol, isMainnet } from './network.js'

export interface TransferResult {
  success: boolean
  txHash: string | undefined
  blockHash: string | undefined
  from: string
  to: string
  amount: string
  network: NetworkId
  symbol: string
  warning?: string
}

export async function transferTokens(
  api: ApiPromise,
  sender: KeyringPair,
  to: string,
  amount: string,
  network: NetworkId,
): Promise<TransferResult> {
  const shannons = ai3ToShannons(amount)
  const tx = transfer(api, to, shannons)

  const result = await signAndSendTx(sender, tx, {}, events.transfer)

  const transferResult: TransferResult = {
    success: result.success,
    txHash: result.txHash,
    blockHash: result.blockHash,
    from: formatAddress(sender.address),
    to,
    amount,
    network,
    symbol: tokenSymbol(network),
  }

  if (isMainnet(network)) {
    transferResult.warning = 'This was a mainnet transaction with real AI3 tokens.'
  }

  return transferResult
}
