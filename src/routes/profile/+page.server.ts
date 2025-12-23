import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
    const { session } = await safeGetSession();

    if (!session) {
        redirect(303, '/');
    }

    const { data: profileData, error } = await supabase
        .from('players')
        .select('*')
        .eq('id', session.user.id)
        .single();

    return { session, profileData };

}


export const actions = {
    signout: async ({ locals: { supabase, safeGetSession } }) => {
        const { session } = await safeGetSession();

        if (session) {
            await supabase.auth.signOut();
            redirect(303, '/');
        }
    },
}