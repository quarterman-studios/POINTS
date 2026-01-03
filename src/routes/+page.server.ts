import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals: { supabase, safeGetSession } }) => {
	const { session } = await safeGetSession();

	const leaderboardLimit = 10;

	if (!session) {
		//Display generic leaderboard
		const { data: leaderboard } = await supabase
			.from('leaderboard')
			.select('username, points, rank, row_number')
			.order('points', { ascending: false })
			.limit(leaderboardLimit + 1); // +1 to fill the space of the user

		return {
			session: null,
			leaderboard
		};
	}

	
	//Display leaderboard at user's position
	const { data: userProfile } = await supabase
	.from('leaderboard')
	.select('rank, username, points, row_number')
	.eq('id', session.user.id)
	.single();
	
	if (!userProfile) {
		throw redirect(303, 'auth/error?message=Profile not found');
	}
	
	// 2. Fetch "Neighbors" (e.g., 5 above and 5 below)
	const minRowNumber = userProfile.row_number - 5;
	const maxRowNumber = userProfile.row_number + 5;

	const { data: leaderboard } = await supabase
		.from('leaderboard')
		.select('username, points, rank, row_number')
		.gte('row_number', minRowNumber) // Greater than or equal to min
		.lte('row_number', maxRowNumber) // Less than or equal to max
		.limit(leaderboardLimit + 1) // +1 to account for the user themselves
		.order('row_number', { ascending: true });

	const { data: leaderBoardSizeData } = await supabase
		.from('leaderboard')
		.select('row_number')
		.order('row_number', {ascending: false})
		.limit(1);

	let leaderBoardSize : number | null = null;

	if (leaderBoardSizeData)
		leaderBoardSize = leaderBoardSizeData[0].row_number;

	return {
		session,
		userProfile,
		leaderboard, 
		leaderBoardSize
	};
};

export const actions = {
	signout: async ({ locals: { supabase, safeGetSession } }) => {
		const { session } = await safeGetSession();

		if (session) {
			await supabase.auth.signOut();
		}
	}
};
