-- drop table RedditComments;

create table RedditComments(
	ID int generated always as identity,
	CommentCreatedUTC int,
	Subreddit char(1000000),
	Body varchar(1000000)
);

-- select * from RedditComments
