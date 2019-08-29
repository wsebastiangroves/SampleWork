select created_utc, body from Comments where 
				body not like '%I am a bot%' and
				body not like '%this action was performed automatically%' and
				body != '[deleted]'
				
select count(*) from comments where body like '%2020%'