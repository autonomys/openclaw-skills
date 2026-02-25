import { ethers } from 'ethers'
import { blake3HashFromCid, cidFromBlakeHash, cidToString, stringToCid } from '@autonomys/auto-dag-data'

/**
 * Convert a CID string to a bytes32 hex string (Blake3 hash) for the contract.
 */
export function cidToBytes32(cid: string): string {
  const cidObj = stringToCid(cid)
  const blake3Digest = blake3HashFromCid(cidObj)
  return ethers.hexlify(blake3Digest)
}

/**
 * Convert a bytes32 hex string (Blake3 hash) from the contract back to a CID string.
 * Returns undefined if the hash is the zero hash (no CID anchored).
 */
export function bytes32ToCid(hash: string): string | undefined {
  if (hash === ethers.ZeroHash) return undefined
  const buffer = Buffer.from(hash.slice(2), 'hex')
  const cid = cidFromBlakeHash(buffer)
  return cidToString(cid)
}

export interface AnchorResult {
  success: boolean
  txHash: string | undefined
  blockHash: string | undefined
  cid: string
  hash: string
  evmAddress: string
  network: string
  warning?: string
}

/**
 * Anchor a CID on-chain by writing its Blake3 hash to the MemoryChain contract.
 */
export async function anchorCid(
  contract: ethers.Contract,
  cid: string,
  evmAddress: string,
  network: string,
): Promise<AnchorResult> {
  const hash = cidToBytes32(cid)

  const tx: ethers.TransactionResponse = await contract.setLastMemoryHash(hash)
  const receipt = await tx.wait()

  return {
    success: !!receipt?.hash,
    txHash: receipt?.hash,
    blockHash: receipt?.blockHash,
    cid,
    hash,
    evmAddress,
    network,
  }
}

export interface GetHeadResult {
  evmAddress: string
  cid: string | undefined
  hash: string
  network: string
}

/**
 * Read the last anchored CID for an EVM address from the MemoryChain contract.
 * Returns undefined cid if no hash has been set.
 */
export async function getHeadCid(
  contract: ethers.Contract,
  evmAddress: string,
  network: string,
): Promise<GetHeadResult> {
  let hash: string
  try {
    hash = await contract.getLastMemoryHash(evmAddress)
  } catch (err) {
    // ethers throws BAD_DATA when calling a non-existent contract (returns 0x).
    // This can happen if the MemoryChain contract isn't deployed on this network.
    const message = err instanceof Error ? err.message : String(err)
    if (message.includes('BAD_DATA') || message.includes('could not decode result data')) {
      throw new Error(
        `MemoryChain contract not available on network "${network}". ` +
          'The contract may not be deployed on this network yet.',
      )
    }
    throw err
  }

  const cid = bytes32ToCid(hash)

  return {
    evmAddress,
    cid,
    hash,
    network,
  }
}
