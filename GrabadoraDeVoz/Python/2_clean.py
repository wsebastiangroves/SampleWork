#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 17 09:21:29 2019

@author: wesgroves
"""
import psycopg2 #Connects python to postgresql
import pandas as pd

try:
        connection = psycopg2.connect(user = "postgres",
                                      password = ,
                                      host = "localhost",
                                      port = "5432",
                                      database = "postgres")
        cursor = connection.cursor()
        query = "select CommentCreatedUTC, Subreddit, Body from RedditComments"
        cursor.execute(query)
        df = cursor.fetchall()
except (Exception, psycopg2.Error) as error :
        print ("Error while connecting to PostgreSQL", error)
finally:
        #closing database connection.
            if(connection):
                cursor.close()
                connection.close()  
                
df = pd.DataFrame(df, columns = ['CommentCreatedUTC', 'Subreddit', 'Body'])
df['Subreddit'] = [x.strip() for x in df['Subreddit']]

