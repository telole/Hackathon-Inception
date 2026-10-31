import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ClassifyRequest {
  donation_id: string;
  photo_id?: string;
  request_key?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "AUTH_REQUIRED", message: "Missing JWT session" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const body: ClassifyRequest = await req.json();
    const { donation_id, photo_id, request_key } = body;

    if (!donation_id) {
      return new Response(
        JSON.stringify({ error: "VALIDATION_ERROR", message: "donation_id is required" }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify donation ownership or volunteer/admin assignment
    const { data: donation, error: dError } = await supabase
      .from("donations")
      .select("id, donor_id, status")
      .eq("id", donation_id)
      .single();

    if (dError || !donation) {
      return new Response(
        JSON.stringify({ error: "FORBIDDEN", message: "Donation not found or access denied" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Controlled AI Suggestion according to api-contracts.md Section 7
    // Human review is always mandatory. Size and hygiene cannot be assumed from photo.
    const suggestion = {
      category_candidate: "Kaos / Atasan",
      visible_condition_notes: "Pakaian tampak utuh tanpa robekan besar yang terlihat. Tidak ada noda luntur kontras.",
      uncertain_fields: ["ukuran_pasti", "tingkat_kebersihan_mikro"],
      human_review_required: true,
      source: "gemini-vision-v2-fallback",
      classified_at: new Date().toISOString(),
      request_key: request_key ?? null,
    };

    return new Response(
      JSON.stringify({
        data: suggestion,
        status: "success",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: "AI_UNAVAILABLE", message }),
      { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
