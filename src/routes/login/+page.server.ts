import { fail, redirect, type Actions } from "@sveltejs/kit"
import type { PageServerLoad } from "./$types"

export const load: PageServerLoad = async ({ url, locals: { safeGetSession } }) => {
	const { session } = await safeGetSession();

	if (session) {
		redirect(303, '/home');
	}

	return { url: url.origin }
}

export const actions: Actions = {
	"magic-link-signin": async (event) => {
		const {
			url,
			request,
			locals: { supabase }
		} = event;

		const formData = await request.formData();
		const email = formData.get("email") as string;
		const username = formData.get("username") as string;
		const validEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

		if (!validEmail) {
			return fail(400, {
				errors: {
					email: "Please enter a valid email address."
				}
			});
		}

		const { error } = await supabase.auth.signInWithOtp({
			email,
			options: {
				data: {
					username: username || null,
				},
				emailRedirectTo: `${url.origin}/auth/confirm`
			},
		});

		if (error) {
			console.error("Error sending magic link:", error.message);
			return fail(400, {
				success: false,
				email,
				message: "There was an issue, please contact support."
			})
		}

		return {
			success: true,
			email,
			message: "Check your email for the magic link to log in!"
		}
	},

	signout: async ({ locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();

		if (session) {
			await supabase.auth.signOut();
		}
	},
}