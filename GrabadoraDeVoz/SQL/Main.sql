-----------------
---Primary script for creating the main data tables: Submissions and Comments
-----------------

--drop table Submissions; drop table Comments;

---Submissions-----
create table Submissions(
	insertedon TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	title varchar(1000),
	id varchar(10),
	created_utc int,
	score int,
	upvote_ratio float,
	num_comments int,
	subreddit varchar(21), --21 is the current maximum length of a subreddit name (July 2019)
	selftext varchar(1000000)
);

----Comments------
create table Comments(
	insertedon TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	id varchar(10),
	created_utc int,
	score int, 
	body varchar(1000000),
	subreddit varchar(21),
	parent_id varchar(10) --check ReadMe.txt for parent_id prefixes definitions
);
