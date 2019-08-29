***************************
*GrabadoraDeVoz ReadMe.txt*
***************************

Comment Sort Types:
Best - A prediction based on the proportion of upvotes/downvotes (see: http://www.evanmiller.org/how-not-to-sort-by-average-rating.html)
Top - Sheer number of current votes
Hot - time dependent, most number of votes 'recently'
New - Latest timestamp
Old - Oldest timestamp
Controversial - High frequency of both up and down votes
Q&A - For AMAs, I assume. Not sure how this is sorted yet


SQL
Table = Comments
parent_id prefix definitions:
--List of prefixes from https://www.reddit.com/dev/api#fullnames
-- t1_	Comment
-- t2_	Account
-- t3_	Link (includes text posts)
-- t4_	Message
-- t5_	Subreddit
-- t6_	Award

POSTGRESQL DATABASE
Connectivity
You will need to set up your own postgresql db. I've inserted placeholders into the python scripts, but these obviously need to be replaced with real values that allow you to connect to your own db.

REDDIT API ACCESS
Connectivity
You will need to set up your own Reddit API access. There are placeholders where your reddit API information must go.