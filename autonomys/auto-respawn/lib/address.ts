import { address as encodeAddress, decode } from '@autonomys/auto-utils'

/**
 * Validate and normalise a consensus-layer address.
 *
 * Accepted formats:
 *   - su...  (Autonomys SS58 prefix 6094) — passed through
 *   - 5...   (Substrate generic prefix 42) — converted to su...
 *
 * Anything else is rejected with a clear error message.
 */
export function normalizeAddress(input: string): string {
  // Quick prefix check before we attempt decoding
  if (!input.startsWith('su') && !input.startsWith('5')) {
    throw new Error(
      `Invalid address prefix: "${input.slice(0, 6)}…". ` +
        'Expected an Autonomys address (su…) or a Substrate address (5…).',
    )
  }

  // Attempt to decode → re-encode at Autonomys prefix 6094
  let publicKey: Uint8Array
  try {
    publicKey = decode(input)
  } catch {
    throw new Error(
      `Invalid address: "${input}". Could not decode as a valid SS58 address.`,
    )
  }

  // Re-encode with Autonomys prefix (6094 is the default in auto-utils)
  const normalized = encodeAddress(publicKey)

  return normalized
}
