import { describe, it, expect } from 'vitest'
import { isConsensusAddress, isEvmAddress, normalizeEvmAddress } from '../lib/address.js'

// Known valid addresses for testing (from Autonomys SDK documentation / real test data)
const VALID_EVM = '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045'
const VALID_EVM_LOWER = '0xd8da6bf26964af9d7eed9e03e53415d37aa96045'

describe('isConsensusAddress', () => {
  it('rejects EVM addresses', () => {
    expect(isConsensusAddress(VALID_EVM)).toBe(false)
  })

  it('rejects empty string', () => {
    expect(isConsensusAddress('')).toBe(false)
  })

  it('rejects random strings', () => {
    expect(isConsensusAddress('hello')).toBe(false)
  })
})

describe('isEvmAddress', () => {
  it('accepts valid checksummed EVM address', () => {
    expect(isEvmAddress(VALID_EVM)).toBe(true)
  })

  it('accepts valid lowercase EVM address', () => {
    expect(isEvmAddress(VALID_EVM_LOWER)).toBe(true)
  })

  it('accepts addresses without 0x prefix (ethers is lenient)', () => {
    // ethers.isAddress accepts bare hex of correct length
    expect(isEvmAddress('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045')).toBe(true)
  })

  it('rejects too-short addresses', () => {
    expect(isEvmAddress('0x1234')).toBe(false)
  })

  it('rejects empty string', () => {
    expect(isEvmAddress('')).toBe(false)
  })

  it('rejects consensus addresses', () => {
    expect(isEvmAddress('su1234567890')).toBe(false)
  })
})

describe('normalizeEvmAddress', () => {
  it('checksums a valid lowercase address', () => {
    const result = normalizeEvmAddress(VALID_EVM_LOWER)
    expect(result).toBe(VALID_EVM)
  })

  it('passes through an already-checksummed address', () => {
    const result = normalizeEvmAddress(VALID_EVM)
    expect(result).toBe(VALID_EVM)
  })

  it('throws on missing 0x prefix', () => {
    expect(() => normalizeEvmAddress('d8dA6BF26964aF9D7eEd9e03E53415D37aA96045'))
      .toThrow(/Expected an address starting with 0x/)
  })

  it('throws on invalid hex', () => {
    expect(() => normalizeEvmAddress('0xZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ'))
      .toThrow(/Not a valid Ethereum address/)
  })
})
