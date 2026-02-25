import type { ethers } from 'ethers'

export interface AnchorResult {
  success: boolean
  txHash: string | undefined
  blockHash: string | undefined
  cid: string
  evmAddress: string
  network: string
  warning?: string
}

/**
 * Anchor a CID on-chain by writing it to the MemoryChain contract.
 * Calls updateHead(string cid) — the contract stores the CID string directly.
 */
export async function anchorCid(
  contract: ethers.Contract,
  cid: string,
  evmAddress: string,
  network: string,
): Promise<AnchorResult> {
  const tx: ethers.TransactionResponse = await contract.updateHead(cid)
  const receipt = await tx.wait()

  return {
    success: !!receipt?.hash,
    txHash: receipt?.hash,
    blockHash: receipt?.blockHash,
    cid,
    evmAddress,
    network,
  }
}

export interface GetHeadResult {
  evmAddress: string
  cid: string | undefined
  network: string
}

/**
 * Read the last anchored CID for an EVM address from the MemoryChain contract.
 * Calls getHead(address) — returns the CID string directly, or undefined if none set.
 */
export async function getHeadCid(
  contract: ethers.Contract,
  evmAddress: string,
  network: string,
): Promise<GetHeadResult> {
  let cid: string
  try {
    cid = await contract.getHead(evmAddress)
  } catch (err) {
    // ethers throws BAD_DATA when calling a non-existent contract (returns 0x).
    const message = err instanceof Error ? err.message : String(err)
    if (message.includes('BAD_DATA') || message.includes('could not decode result data')) {
      throw new Error(
        `MemoryChain contract not available on network "${network}". ` +
          'The contract may not be deployed at the configured address.',
      )
    }
    throw err
  }

  return {
    evmAddress,
    cid: cid || undefined,
    network,
  }
}
