import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { RtcTokenBuilder, RtcRole } from "npm:agora-token@2.0.3"

serve(async (req) => {
  const { channel, uid } = await req.json()
  const appId = Deno.env.get("AGORA_APP_ID")!
  const appCert = Deno.env.get("AGORA_APP_CERT")!
  const expire = 3600
  const now = Math.floor(Date.now()/1000)
  const privilegeExpiredTs = now + expire
  const token = RtcTokenBuilder.buildTokenWithUid(appId, appCert, channel, uid ?? 0, RtcRole.PUBLISHER, privilegeExpiredTs)
  return new Response(JSON.stringify({ token, appId, expire }), { headers: { "Content-Type": "application/json" } })
})
