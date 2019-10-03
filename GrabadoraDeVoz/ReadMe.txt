***************************
*GrabadoraDeVoz ReadMe.txt*
***************************

The original purpose of this tool was to utilize Reddit user comment data to create sentiment analyses across 'subreddits' (sub-forums for specific topics). The idea is to first 'ask' a subreddit to 'discuss' a topic and to observationally compare the short discussions across subreddits for each topic. The second step is to generate an actual sentiment score for comments, different scores for the same topic between subreddits could reveal interesting insights. 

The final idea could be expanded to an assessment tool usable on any larger communities. 



********
Assorted Data Documentation:
********



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