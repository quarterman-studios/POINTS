import { PUBLIC_SUPABASE_PUBLISHABLE_KEY, PUBLIC_SUPABASE_URL } from "$env/static/public";
import { createBrowserClient, isBrowser, createServerClient } from "@supabase/ssr";

import type { LayoutLoad } from "./$types";

export const load: LayoutLoad = async ({ fetch, data, depends }) => {
	depends("supabase:auth");

	const supabase = isBrowser()
		? createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
			global: { fetch }
		})
		: createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY, {
			global: { fetch },
			cookies: {
				getAll() {
					return data.cookies;
				},
			}
		})

	const { data: { session }, error } = await supabase.auth.getSession();
	if (error) {
		console.error("Error getting session:", error.message);
	}

	return { supabase, session };
}