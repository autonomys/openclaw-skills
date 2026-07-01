import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { resolvePassphrase, resolveMnemonic } from '../lib/wallet.js'

describe('resolvePassphrase', () => {
  const originalEnv = process.env.AUTO_RESPAWN_PASSPHRASE

  beforeEach(() => {
    delete process.env.AUTO_RESPAWN_PASSPHRASE
  })

  afterEach(() => {
    if (originalEnv !== undefined) {
      process.env.AUTO_RESPAWN_PASSPHRASE = originalEnv
    } else {
      delete process.env.AUTO_RESPAWN_PASSPHRASE
    }
  })

  it('returns explicit argument when provided', async () => {
    process.env.AUTO_RESPAWN_PASSPHRASE = 'from-env'
    const result = await resolvePassphrase('from-arg')
    expect(result).toBe('from-arg')
  })

  it('falls back to env var when no argument', async () => {
    process.env.AUTO_RESPAWN_PASSPHRASE = 'from-env'
    const result = await resolvePassphrase()
    expect(result).toBe('from-env')
  })

  it('throws when no passphrase source is available (non-TTY)', async () => {
    // No argument, no env var, no file, and not a TTY — should throw
    await expect(resolvePassphrase()).rejects.toThrow(/No passphrase found/)
  })
})

describe('resolveMnemonic', () => {
  it('returns the explicit argument when provided (deprecated flag path)', async () => {
    const result = await resolveMnemonic('word '.repeat(11) + 'word')
    expect(result).toBe('word '.repeat(11) + 'word')
  })

  it('throws with stdin guidance when no source and non-TTY', async () => {
    // No argument, useStdin not set, and not a TTY under vitest — should throw
    await expect(resolveMnemonic()).rejects.toThrow(/--mnemonic-stdin|run interactively/)
  })
})
