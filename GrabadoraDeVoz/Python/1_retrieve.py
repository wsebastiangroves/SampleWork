#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 17 09:21:29 2019

This script utilizes Reddit's API to gather comment and submission data and
store select portions in a local postgresql database.

I'm keeping any links/urls at this stage, we might actually want to use them.

@author: wesgroves
"""

##Libraries
import psycopg2 #Connects python to postgresql
import psycopg2.extras #Connects python to postgresql
import praw #Python Reddit API Wrapper
import datetime as dt
from expandContractions import expandContractions
import re
from random import sample

##Functions
def FromUTC(a):
    
    ###
    #Takes a UTC code, gives back the full datetime
    ###
    
    return dt.datetime.fromtimestamp(a) 
        

def SubmissionCleaner(sub):
    
    ###
    #cleans text attributes of submissions
    ###
    
    #Clean the title
    sub.title = sub.title.lower() #lowercase text
    sub.title = re.sub('’|‘','\'', sub.title) #standardize apostrophes
    sub.title = expandContractions(sub.title)
    sub.title = re.sub('\'|`|"', '', sub.title)
    
    #Clean the selftext
    sub.selftext = sub.selftext.lower() #lowercase text
    sub.selftext = re.sub('’|‘','\'', sub.selftext) #standardize apostrophes
    sub.selftext = expandContractions(sub.selftext)
    sub.selftext = re.sub('\'|`|"', '', sub.selftext)
    
    #Turn into tuple for easier storage into postgreSQL
    tup = (sub.title
                , sub.id
                , int(sub.created_utc)
                , sub.score
                #, sub.upvote_ratio
                , sub.num_comments
                , str(sub.subreddit)
                , sub.selftext)
    
    return(tup)


def CommentCleaner(comment):
    
    ###
    #cleans the body of the comment, returns in tuple form
    ###
    
    #clean the body 
    comment.body = comment.body.lower() #lowercase text
    comment.body = re.sub('’|‘','\'', comment.body) #standardize apostrophes 
    comment.body = expandContractions(comment.body) 
    comment.body = re.sub('\'|`|"', '', comment.body) #remove any remaining apostrophes assuming they are a part of possessive nouns  mostly now
    
    #Turn into tuple for easier storage into postgreSQL
    tup = (comment.id
                , int(comment.created_utc)
                , comment.score
                , comment.body
                , str(comment.subreddit)
                , comment.parent_id)
    
    return(tup)

def GatherComments(sub, sort, limit, threshold):

    ############################################################
    #Takes a submission instance, extracts comments (with options), and cleans text
    #Cleans using CommentCleaner
    ############################################################
    
    #limit: defines the number of MoreComments types to be expanded into Comments
        #'None' for infinite, 0 for remove all MoreComments from Comment Forest .
        #If 0 is used, it will output all MoreComments
    #threshold: defines number of children comments a MoreComments instance needs to be expanded
        #The "LoadMoreComments" option on Reddit at the bottom of long threads
        #can only be expanded if threshold = 0
        
    ############################################################
    
    #Sort the comments
    if not sort:
        sort = 'Best'
    if sort not in ['Best', 'Top', 'New', 'Controversial', 'Old', 'Q&A']:
        return print('sort = Best, Top, New, Controversial, Old, or Q&A')
    sub.comment_sort = sort
    
    #Replace MoreComments type with Comments type (or don't, depends on limit)
    sub.comments.replace_more(limit = limit, threshold = threshold)
        
    #Organize comments for storage, and return list of tuples
    return list(map(CommentCleaner, sub.comments.list()))
    

#def Recoger(subred, related_subs = False, fetch_new = False): #Recoger is 'collect' in spanish
    
        ###
        #Function to collect and store submissions and comments from Reddit
        ###
        #fetch_new = T would go get new data
        #related_subs = T would grab the related subs listed in the subreddit of interest
        #subred = '' grabs the subreddit of interest, its posts and comments
        
#Open connection with reddit api
reddit = praw.Reddit(client_id='5CBp36FgwpVpxw', \
                 client_secret='P1EbSSG_FdzjeG8OSUEk7xfMSQk', \
                 user_agent='GrabadoraDeVoz', \
                 username='GrabadoraDeVoz', \
                 password='HT2hM97svpzSsHB', \
                 redirect_uri='http://localhost') 

#Establish postgreSQL connection
try:
    connection = psycopg2.connect(user = "postgres",
                                  password = "Ks190O20?!",
                                  host = "localhost",
                                  port = "5432",
                                  database = "postgres")
    cursor = connection.cursor()
    
    ###############
    ##SUBMISSIONS##
    ###############
    
    #Query the subreddits of interest (need related subreddits section here)
    subred = 'the_donald'
    subreddit = reddit.subreddit(subred)
    submissions = subreddit.top('week')
    
    #Extract submission data
    submissions = [x for x in submissions]
    
    #Organize submissions for storage
    submissions_tuplist = list(map(SubmissionCleaner, submissions))
    
    #Insert into local db
    query = 'INSERT INTO Submissions (title, id, created_utc, score, num_comments, subreddit, selftext) VALUES %s'
    
    #Send data to postgresql database
    psycopg2.extras.execute_values(cursor, query, submissions_tuplist, template = None, page_size = 100)
        
    #Commit changes to database
    connection.commit()
    
    ###############
    ## COMMENTS  ##
    ###############
    
    i=0
    for submission in submissions: #I made a for loop because a tuple consisting of all comments from all subs would be too large imo
        
        #Organize comments for storage 
        comments_tuplist = GatherComments(submission
                                          , sort = 'Best'
                                          , limit = None
                                          , threshold = 0) #These current settings gather all comments in the thread
    
        #Insert into local db
        query = 'INSERT INTO Comments (id, created_utc, score, body, subreddit, parent_id) VALUES %s'
        
        #Send data to postgresql database
        psycopg2.extras.execute_values(cursor, query, comments_tuplist, template = None, page_size = 1000)
            
        #Commit changes to database
        connection.commit() 
        
        #Print off %complete and a sample comment
        i+=1
        print(sample(comments_tuplist, 1))
        print('\n', sample(comments_tuplist, 1))
        print('\n', sample(comments_tuplist, 1))
        print(f'{i/len(submissions)*100}'+'% complete')
        timer_b = dt.datetime.now() #6min for 24k comments
        print(timer_b - timer_a)
        
except (Exception, psycopg2.Error) as error :
    print ("Error while connecting to PostgreSQL: ", error)
finally:
    #closing database connection.
        if(connection):
            cursor.close()
            connection.close()  
                
#Recoger('the_donald+therightboycott+askthe_donald+headlinecorrections')

#Placeholder Login information
#reddit = praw.Reddit(client_id='PERSONAL_USE_SCRIPT_14_CHARS', \
#                     client_secret='SECRET_KEY_27_CHARS ', \
#                     user_agent='YOUR_APP_NAME', \
#                     username='YOUR_REDDIT_USER_NAME', \
#                     password='YOUR_REDDIT_LOGIN_PASSWORD')
 