------------------------------------------------------------
--Data Duplicate Removal Script-----------------------------
--------------------------------------------------------------------------------------------------------------
-- Rule: One observation per Submissions.id/Comments.id.
-- Description: Delete the row of the id that has a insertedon time stamp less than the max insertedon of that same id.
--------------------------------------------------------------------------------------------------------------


------------------------------------------------------------
---###SUBMISSIONS###----------------------------------------
------------------------------------------------------------

delete from submissions 
using (
		select 
			max(insertedon) mio
			,id
		from submissions
		group by id
	  ) a 
where 
submissions.id = a.id and
submissions.insertedon < a.mio;

------------------------------------------------------------
---###COMMENTS###-------------------------------------------
------------------------------------------------------------

delete from comments 
using (
		select 
			max(insertedon) mio
			,id
		from comments
		group by id
	  ) a 
where 
comments.id = a.id and
comments.insertedon < a.mio
