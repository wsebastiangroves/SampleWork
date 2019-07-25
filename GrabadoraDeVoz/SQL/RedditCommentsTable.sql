-- drop table RedditComments;

create table RedditComments(
	ID int generated always as identity,
	CommentCreatedUTC int,
	Subreddit char(21), --21 is the current maximum length of a subreddit name (2019)
	Body varchar(100000)
);

-- select count(*) from RedditComments
-- select subreddit from RedditComments