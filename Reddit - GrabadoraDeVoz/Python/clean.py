#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jul 17 09:21:29 2019

@author: wesgroves
"""
import zstandard as zstd
import json
import psycopg2
import re
import os
import praw #Python Reddit API Wrapper
import pandas as pd
import datetime as dt

#os.chdir("/Volumes/FreeAgent Drive/reddit data") #my external hard drive

# Credit on reddit goes to 'Watchful1' for the decompression version of the data stream below:
# https://www.reddit.com/r/pushshift/comments/ajmcc0/information_and_code_examples_on_how_to_use_the/ef012vk/?utm_source=share&utm_medium=web2x

with open("RC_2019-03.zst", 'rb') as fh: #I set my working directory to the file's location
    dctx = zstd.ZstdDecompressor()
    with dctx.stream_reader(fh) as reader:
        previous_line = ""
        pb = 0
        while True:
            chunk = reader.read(65536)
            if not chunk:
                break
            #If embedded json then split, process, and store
            #DO THAT AFTER LOADING SOME INTO POSTGRESQL FIRST!!!
            string_data = chunk.decode('utf-8')
            lines = string_data.split("\n")
            #lines = f"{[lines]}"
            for i, line in enumerate(lines[:-1]):
                if i == 0:
                    line = previous_line + line
                object = json.loads(line)        
                try:
                    connection = psycopg2.connect(user = "postgres",
                                                  password = "Ks190O20?!",
                                                  host = "localhost",
                                                  port = "5432",
                                                  database = "postgres")
                    cursor = connection.cursor()
                    
                    # Print PostgreSQL version
                    query = 'insert into RedditComments (CommentCreatedUTC, Subreddit, Body) values ('+ \
                                                            str(object['created_utc'])+",'"+ \
                                                            object['subreddit']+"','"+ \
                                                            re.sub("'", "", object['body'])+"')"
                    cursor.execute(query)
                    connection.commit()
                except (Exception, psycopg2.Error) as error :
                    print ("Error while connecting to PostgreSQL", error)
                finally:
                    #closing database connection.
                        if(connection):
                            cursor.close()
                            connection.close()            
            previous_line = lines[-1]
            pb += 65536
            print(f"{round(pb/14641003798, 4)}") #cool Python 3.6 feature
            
#chunk = dctx.stream_reader(open("RC_2019-03.zst", 'rb')).read(65536)

