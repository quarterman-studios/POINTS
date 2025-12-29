import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
    const { session } = await safeGetSession();

    if (!session) {
        redirect(303, '/');
    }

    const { data: userState, error } = await supabase
        .from('game_state')
        .select('*')
        .eq('id', session.user.id)
        .single();

    if (error || !userState) {
        throw redirect(303, '/auth/error?message=Profile data not found');
    }

    const { data: userProfile } = await supabase
        .from('profiles')
        .select('username, points, rank')
        .eq('id', session.user.id)
        .single();

    return { session, userState, userProfile };

}

export const actions = {
    signout: async ({ locals: { supabase, safeGetSession } }) => {
        const { session } = await safeGetSession();

        if (session) {
            await supabase.auth.signOut();
        }
    },

}