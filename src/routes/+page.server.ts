import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
    const { session } = await safeGetSession();

    if (!session) {
		//Display generic leaderboard

    }

	//Display leaderboard at user's position

}


export const actions = {
    signout: async ({ locals: { supabase, safeGetSession } }) => {
        const { session } = await safeGetSession();

        if (session) {
            await supabase.auth.signOut();
        }
    },
}