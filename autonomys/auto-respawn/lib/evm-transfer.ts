/**
 * Transfer native tokens (AI3/tAI3) between EVM addresses on Auto-EVM.
 */

import { ethers } from 'ethers'
import type { NetworkId } from './network.js'
import { tokenSymbol, isMainnet } from './network.js'

export interface EvmTransferResult {
  success: boolean
  transactionHash: string
  blockNumber: number
  blockHash: string
  gasUsed: string
  from: string
  to: string
  amount: string
  network: NetworkId
  symbol: string
  warning?: string
}

/**
 * Send native tokens from an EVM wallet to another EVM address on Auto-EVM.
 */
export async function transferEvmTokens(
  signer: ethers.Wallet,
  to: string,
  amount: string,
  network: NetworkId,
): Promise<EvmTransferResult> {
  const amountWei = ethers.parseEther(amount)

  const tx = await signer.sendTransaction({
    to,
    value: amountWei,
  })

  const receipt = await tx.wait()

  if (!receipt) {
    throw new Error('Transaction was sent but no receipt was received.')
  }

  const result: EvmTransferResult = {
    success: receipt.status === 1,
    transactionHash: receipt.hash,
    blockNumber: receipt.blockNumber,
    blockHash: receipt.blockHash,
    gasUsed: receipt.gasUsed.toString(),
    from: await signer.getAddress(),
    to,
    amount,
    network,
    symbol: tokenSymbol(network),
  }

  if (isMainnet(network)) {
    result.warning = 'This was a mainnet transaction on Auto-EVM with real AI3 tokens.'
  }

  return result
}
