// src/routes/auth/confirm/+server.js
import type { EmailOtpType } from '@supabase/supabase-js'
import { redirect } from '@sveltejs/kit'

import type { RequestHandler } from './$types'

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {

	console.log('Confirm URL:', url.toString());

	const errorDescription = url.searchParams.get('error_description')
	if (errorDescription) {
		throw redirect(303, `/auth/error?message=${encodeURIComponent(errorDescription)}`)
	}

	const code = url.searchParams.get('code');
	const next = url.searchParams.get('next') ?? '/'

	/**
	 * Clean up the redirect URL by deleting the Auth flow parameters.
	 *
	 * `next` is preserved for now, because it's needed in the error case.
	 */
	const redirectTo = new URL(url)
	redirectTo.pathname = next
	redirectTo.searchParams.delete('code')


	console.log('Redirect URL after cleanup:', redirectTo.toString());

	if (code) {
		const { error } = await supabase.auth.exchangeCodeForSession(code);

		if (!error) {
			redirectTo.searchParams.delete('next')
			redirect(303, redirectTo)
		} else {
			redirectTo.pathname = '/auth/error?message=' + encodeURIComponent(error.message)
			redirect(303, redirectTo)
		}
	}

	redirect(303, '/auth/error?message=No%20code%20provided%20for%20confirmation.')
}