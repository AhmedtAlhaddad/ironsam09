import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const safeErrorCodes = new Set([
  "invalid_customer_name",
  "invalid_phone",
  "invalid_city",
  "invalid_address",
  "invalid_notes",
  "cart_empty",
  "product_unavailable",
  "size_unavailable",
  "color_mismatch",
  "insufficient_stock",
  "invalid_discount",
  "order_rate_limited",
]);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function digest(value: string) {
  const bytes = new TextEncoder().encode(value);
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(hash))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function errorCode(message: string) {
  const code = message.split(":", 1)[0];
  return safeErrorCodes.has(code) ? code : "order_failed";
}

async function verifyTurnstile(token: string, secret: string, ip: string) {
  const form = new URLSearchParams({ secret, response: token });
  if (ip !== "unknown") form.set("remoteip", ip);
  const response = await fetch(
    "https://challenges.cloudflare.com/turnstile/v0/siteverify",
    { method: "POST", body: form },
  );
  if (!response.ok) return false;
  const result = await response.json();
  return result.success === true;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch (_) {
    return json({ error: "invalid_request" }, 400);
  }

  const ip = request.headers.get("cf-connecting-ip")?.trim()
    || request.headers.get("x-forwarded-for")?.split(",")[0]?.trim()
    || "unknown";
  const phone = typeof body.p_phone === "string" ? body.p_phone.trim() : "";
  const rateKey = await digest(`${ip}|${phone}`);

  const turnstileSecret = Deno.env.get("TURNSTILE_SECRET_KEY");
  if (Deno.env.get("TURNSTILE_ENFORCED") === "true") {
    const token = typeof body.turnstile_token === "string"
      ? body.turnstile_token
      : "";
    if (!turnstileSecret || !token || !(await verifyTurnstile(token, turnstileSecret, ip))) {
      return json({ error: "verification_required" }, 403);
    }
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "server_not_configured" }, 503);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { turnstile_token: _, ...orderParams } = body;
  const { data, error } = await admin.rpc("submit_order_guarded", {
    ...orderParams,
    p_rate_key: rateKey,
  });

  if (error) {
    const code = errorCode(error.message);
    return json({ error: code }, code === "order_rate_limited" ? 429 : 400);
  }
  return json(data);
});
