#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 17 09:21:29 2019

@author: wesgroves
"""
import psycopg2 #Connects python to postgresql
import re
import praw #Python Reddit API Wrapper
import datetime as dt

def FromUTC(asdf):
    return dt.datetime.fromtimestamp(asdf)

def SubredditToStorage(subred):
    
    #Placeholder Login information, the following is required and must be uncommented and filled out
    #reddit = praw.Reddit(client_id='PERSONAL_USE_SCRIPT_14_CHARS', \
    #                     client_secret='SECRET_KEY_27_CHARS ', \
    #                     user_agent='YOUR_APP_NAME', \
    #                     username='YOUR_REDDIT_USER_NAME', \
    #                     password='YOUR_REDDIT_LOGIN_PASSWORD')
 
    
    sbrd = reddit.subreddit(subred)
    try:
        connection = psycopg2.connect(user = "postgres",
                                      password = ,
                                      host = "localhost",
                                      port = "5432",
                                      database = "postgres")
        cursor = connection.cursor()
        i=0
        for comment in sbrd.stream.comments(skip_existing=True):   
            i += 1
            query = "insert into RedditComments (CommentCreatedUTC, Subreddit, Body) values ("+ \
                                                str(int(comment.created_utc))+",'"+ \
                                                str(comment.subreddit)+"','"+ \
                                                re.sub("'", '"', comment.body)+"')"
            cursor.execute(query)
            connection.commit()
            print(f'vvvPosted Timestamp: {FromUTC(comment.created_utc)}\n\n^^^Post: '+comment.body+'\n\n')
            print(f'comment#: {i}\n\n')
            if i == 1:
                print(f"goal of {i} reached")
                break
    except (Exception, psycopg2.Error) as error :
        print ("Error while connecting to PostgreSQL", error)
    finally:
        #closing database connection.
            if(connection):
                cursor.close()
                connection.close()  
    return;
                    
                    
#Placeholder Login information
#reddit = praw.Reddit(client_id='PERSONAL_USE_SCRIPT_14_CHARS', \
#                     client_secret='SECRET_KEY_27_CHARS ', \
#                     user_agent='YOUR_APP_NAME', \
#                     username='YOUR_REDDIT_USER_NAME', \
#                     password='YOUR_REDDIT_LOGIN_PASSWORD')
 