import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	const leaderboardLimit = 10;

	if (!session) {
		//Display generic leaderboard
		const { data: leaderboard } = await supabase
			.from('profiles')
			.select('username, points, rank')
			.order('points', { ascending: false })
			.limit(leaderboardLimit+1); // +1 to fill the space of the user

		return {
			session: null,
			leaderboard
		};

	}

	//Display leaderboard at user's position
	const { data: userProfile } = await supabase
		.from('profiles')
		.select('rank, username, points')
		.eq('id', session.user.id)
		.single();

	if (!userProfile) {
		throw redirect(303, 'auth/error?message=Profile not found');
	}

	// 2. Fetch "Neighbors" (e.g., 5 above and 5 below)
	const minRank = userProfile.rank - 5;
	const maxRank = userProfile.rank + 5;

	const { data: leaderboard } = await supabase
		.from('profiles')
		.select('username, points, rank')
		.gte('rank', minRank) // Greater than or equal to min
		.lte('rank', maxRank) // Less than or equal to max
		.limit(leaderboardLimit+1) // +1 to account for the user themselves
		.order('rank', { ascending: true });

	return {
		session,
		userProfile,
		leaderboard
	};
}


export const actions = {
	signout: async ({ locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();

		if (session) {
			await supabase.auth.signOut();
		}
	},
}