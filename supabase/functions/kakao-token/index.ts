// 카카오 인가 코드 → OpenID Connect ID 토큰 교환
// Client Secret 이 브라우저에 노출되지 않도록 서버(Supabase Edge Function)에서만 처리해요.
// 필요한 시크릿: KAKAO_REST_KEY, KAKAO_CLIENT_SECRET

const ALLOWED = ['https://dusohee.github.io', 'http://localhost:3000'];

Deno.serve(async (req) => {
  const origin = req.headers.get('origin') ?? '';
  const cors = {
    'Access-Control-Allow-Origin': ALLOWED.includes(origin) ? origin : ALLOWED[0],
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  };
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  try {
    const { code, redirect_uri } = await req.json();
    if (typeof code !== 'string' || !ALLOWED.some((o) => String(redirect_uri).startsWith(o + '/'))) {
      return json({ error: 'bad_request' }, 400);
    }
    const r = await fetch('https://kauth.kakao.com/oauth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: Deno.env.get('KAKAO_REST_KEY') ?? '',
        client_secret: Deno.env.get('KAKAO_CLIENT_SECRET') ?? '',
        redirect_uri,
        code,
      }),
    });
    const t = await r.json();
    if (!r.ok || !t.id_token) return json({ error: t.error ?? 'token_failed', detail: t.error_description }, 400);
    return json({ id_token: t.id_token });   // access/refresh 토큰은 돌려주지 않아요
  } catch (_e) {
    return json({ error: 'server_error' }, 500);
  }
});
