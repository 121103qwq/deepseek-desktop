import { readFile, writeFile } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { join } from 'node:path'

const [home, enabledValue, modelMode] = process.argv.slice(2)
if (!home || !['true', 'false'].includes(enabledValue) || !['free', 'deepseek'].includes(modelMode)) {
  throw new Error('Configure Vision.mjs received invalid arguments')
}

const enabled = enabledValue === 'true'
const profileRoot = join(home, 'profiles', 'web')
const packagePath = join(profileRoot, 'package.json')
const patchPath = join(profileRoot, 'cordis.patch.yml')
const bundleName = 'dsh-vision-sidecar'
const beginMarker = '# BEGIN DEEPSEEK DESKTOP VISION'
const endMarker = '# END DEEPSEEK DESKTOP VISION'

if (!existsSync(packagePath) || !existsSync(patchPath)) {
  throw new Error('The DSH web profile was not initialized')
}

const manifest = JSON.parse(await readFile(packagePath, 'utf8'))
const bundles = manifest?.dsh?.profile?.bundles
if (!Array.isArray(bundles)) throw new Error('The DSH web profile manifest is invalid')
manifest.dsh.profile.bundles = bundles.filter((bundle) => bundle !== bundleName)
if (enabled) manifest.dsh.profile.bundles.push(bundleName)
await writeFile(packagePath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8')

let patch = await readFile(patchPath, 'utf8')
const markerPattern = new RegExp(`(?:\\r?\\n)?${beginMarker}[\\s\\S]*?${endMarker}(?:\\r?\\n)?`, 'g')
patch = patch.replace(markerPattern, '\n').trimEnd()
if (enabled) {
  const targetProvider = modelMode === 'free' ? 'kilo' : 'deepseek-official'
  const targetModel = modelMode === 'free' ? 'kilo-auto/free' : 'deepseek-v4-flash'
  patch += `\n\n${beginMarker}\n- id: vision-sidecar\n  config:\n    targetProvider: ${targetProvider}\n    targetModel: ${targetModel}\n\n- id: agent-default-model\n  config:\n    provider: deepseek-vision\n    model: deepseek-with-vision\n${endMarker}`
}
await writeFile(patchPath, `${patch}\n`, 'utf8')
