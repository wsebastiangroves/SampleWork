#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: wesgroves

@description: This script is very fluid and extremely tentative. It is for the
purpose of using NLP on freely available data from Reddit.
"""

##
#Libraries
##

import psycopg2
from nltk.tokenize import RegexpTokenizer
from gensim.models import Word2Vec
from sklearn.decomposition import PCA
import pandas as pd
import plotly.express as px
from plotly.offline import plot
import re
import itertools
import datetime as dt
import numpy as np
from keras.utils import np_utils
from tensorflow.python.keras.models import Sequential
from tensorflow.python.keras.layers import Dense, Dropout, LSTM
#import retrieve initiate() function
import random
random.seed(10)



##
#Functions
##

def FromUTC(a):
    
    ###
    #Takes a UTC code, gives back the full datetime
    ###
    
    return dt.datetime.fromtimestamp(a) 

def WordCount (input_string, word):
    
    ##
    #Function to count the occurence of a word in a single string.
    #Very fast even when using a very large string instance
    ##

    return sum(1 for _ in re.finditer(r'\b%s\b' % re.escape(f'{word}'), input_string))

def expand_grid(data_dict):
    
    ##
    #SOURCE: https://pandas.pydata.org/pandas-docs/stable/user_guide/cookbook.html#creating-example-data
    ##
    #Function to mimic R's expand.grid(), 
    #Feed it a dictionary and receive all combinations of values across the keys
    ##

    rows = itertools.product(*data_dict.values())
    return pd.DataFrame.from_records(rows, columns=data_dict.keys())

def tokenize_words(input):
    
    ##
    #Function to return a list of the individual words, 
    #only underscore: '_' is ignored out of all punctuation
    ##

    #Instantiate the tokenizer
    tokenizer = RegexpTokenizer(r'\w+')
    return tokenizer.tokenize(input)

def NGramBuild(tokenized_comment, window_size):
    
    ##
    #Function to return a list of ngrams on a readied comment 
    #Includes adjustable window size (window_size of 0 means 1gram)
    ##
    
    #Number of words in the comment
    num_words = len(tokenized_comment)
    
    #Exit features
    if num_words == 1:
        return []
    
    #List to fill and return
    ngrams = []
    
    #Build tuples
    for i in range(0, num_words): #i always represents the first word in the source-text sequence
        
#        #Words before target word
#        lower_range = list(range(i - window_size, i))
#        if sum([x < 0 for x in lower_range]) > 0: 
#            []
#        else: 
#            ngrams.append((tokenized_comment[i], tokenized_comment[lower_range[0]:lower_range[-1] + 1]))
        
        #Words after target word
        target_word_index = i + window_size + 1
        source_range = list(range(i, target_word_index))
        if sum([x >= num_words for x in source_range]) > 0 or target_word_index >= num_words:
            continue
        source_list = tokenized_comment[source_range[0]:source_range[-1] + 1]
        target_word = tokenized_comment[target_word_index]
#        ngrams.append((word_index[word_index['word']==tokenized_comment[i]].index.item()
#                        , source_list))
        ngrams.append([source_list, target_word])
    
    #Return built ngrams set
    return ngrams

def Word2Number(word, index = True):
    number = keyDF.loc[keyDF['word']==word]['sum']
    if index:
        return number.index[0]
    if not index:
        return float(number)
        

###################################
#PostgreSQL call for Reddit data
###################################
    

try:
        connection = psycopg2.connect(user = "postgres",
                                      password = "Ks190O20?!",
                                      host = "localhost",
                                      port = "5432",
                                      database = "postgres")
        cursor = connection.cursor()
        
        #our query
        query = "select created_utc, body from Comments where \
				body not like '%I am a bot%' and \
				body not like '%this action was performed automatically%' and \
				body not like '%this bot was created by%' and \
                body != '[deleted]'"
        cursor.execute(query)
        #our tuple list
        comments_data = cursor.fetchall()
        
except (Exception, psycopg2.Error) as error :
        print ("Error while connecting to PostgreSQL", error)
finally:
        #closing database connection.
            if(connection):
                cursor.close()
                connection.close()  



####################
####ORGANIZATION####
####################
               
#Converting to a pandas DF
comments_df = pd.DataFrame(comments_data, columns = ['created_utc', 'body'])

#Remove urls from text
comments_df.loc[:, 'body'] = list(map(lambda x: re.sub(r'http\S+', '', x), comments_df['body']))

#Convert UTC stamps to readable timestamps
comments_df.loc[:, 'created_utc'] = list(map(lambda x: FromUTC(x), comments_df['created_utc']))

#Ready the text for encoding
comments_tokenized = list(map(tokenize_words, comments_df['body']))
    
    
###################################
###WORD2VEC ENCODING OF COMMENTS###
###################################

#Need to review predictive capability with varying model parameters
#in order to determine best vector size and word min_count
model = Word2Vec(size = 32, min_count = 1)
model.build_vocab(sentences = comments_tokenized)
model.train(sentences = comments_tokenized
            , total_examples = model.corpus_count
            , epochs = model.epochs)  

################################
###Word/Key/VectorSum DataFrame#
################################
keyDF = pd.DataFrame(model.wv.index2word, columns = ['word'])
keyDF['sum'] = [sum(model.wv[word]) for word in keyDF['word']]
#word = 'shoutout'
#sum(model.wv[word]) == keyDF.loc[keyDF['word']==word,'sum'] #a test for accuracy
#model.wv.vocab[word].index == keyDF.loc[keyDF['word']==word].index

###############################
#PCA of Word2Vec vectors in 3D#
###############################

##The size of word_index is dependent on the number of vectors chosen during model instantiation
#word_index = pd.DataFrame(model.wv.index2word, columns = ['word'])
#word_index['array'] = [model.wv[word] for word in word_index['word']] #Could probably do these lines all in shorter code
#                                                                        #nested vectors for pca are in 'array' from .wv[word]
#word_index = word_index.array.apply(pd.Series) \
#    .merge(word_index, left_index = True, right_index = True) #Expand array and merge onto our df
#word_index = pd.DataFrame.drop(word_index, labels = 'array', axis = 1) #Drop the original nested vector column
##run the pca on our vectors
#x = word_index.drop('word', axis = 1) 
#pca = PCA(n_components=3) #reduces vector space to 3 dimensions
#principalComponents = pca.fit_transform(x)
#principalDf = pd.DataFrame(data = principalComponents 
#                           , columns = ['principal component 1'
#                                       , 'principal component 2'
#                                       , 'principal component 3'])
#word_index = pd.concat([principalDf, word_index], axis = 1)
#word_slice = word_index.loc[word_index['word'].isin(['man','woman'
#                                                      ,'king','queen'
#                                                      ,'walking','walked'
#                                                      ,'swim','swam'])]
#word_slice = word_slice.reset_index(drop=True)
#word_freq = pd.Series([WordCount(' . '.join(comments_df['body']), x) for x in word_slice['word']])
#word_slice.insert(loc=0, column='freq', value=word_freq)
#fig = px.scatter_3d(word_slice
#                 , x = 'principal component 1'
#                 , y = 'principal component 2'
#                 , z = 'principal component 3'
#                 , hover_data = ['word', 'freq'])
#fig.show()
#plot(fig)

########################
##TRAINING SET CREATION#
########################

##Build Ngram of choice
gramls = []
#The larger the window, the fewer the observations in the training set.
#The fewer the observations, the faster the ngrams build
#Remember, window_size = 0 in NGramBuild is a 1gram, 1 is a 2gram, and so on...
ngrams = list(map(lambda x: NGramBuild(x, 2), comments_tokenized))
for expanded_comment in ngrams:
    for obsv in expanded_comment:
        gramls.append(obsv)
grams_DF = pd.DataFrame(gramls, columns=['source','target'])
source_len = len(grams_DF['source'][0]) #this is equal to NGramBuild window_size + 1
#create word columns consisting of each word in the source
for i in range(0, source_len):
    name = 'word' + str(i + 1)
    grams_DF[name] = [x[i] for x in grams_DF['source']]
#Find all the 'word' columns we created, and join vector sums to new source word columns
word_columns = [re.match('word', column) != None for column in list(grams_DF.columns)]
word_columns = [x for x in grams_DF.columns[word_columns]]
i = 0
for column in word_columns:
    grams_DF = grams_DF.join(keyDF.set_index('word') #join vector sums to words
                                , on=column
                                , how='left'
                                , rsuffix=f'{i+1}')
    i+=1
del i
#Join indexing to target word for model
grams_DF = grams_DF.join(keyDF.drop('sum', axis = 1)\
                           .reset_index()\
                           .set_index('word')
                            , on='target'
                            , how='left')
#Rename for sanity/uniformity
grams_DF = grams_DF.rename(columns={'sum': 'sum1'})
grams_DF = grams_DF.rename(columns={'index': 'targetindex'}) 
#Find all the 'sum' columns 
sum_columns = [re.match('sum', column) != None for column in list(grams_DF.columns)]
sum_columns = [x for x in grams_DF.columns[sum_columns]]
#Training sets
X = grams_DF[sum_columns]
y_train = [y for y in grams_DF['targetindex']] 
Y = np_utils.to_categorical(y_train)
#X = []  
#for i in range(0, len(x_train)):
#    temp = []
#    for column in sum_columns:
#        temp.append(x_train[column][i])
#    X.append(temp)
#X = np.reshape(x_train, (len(x_train), source_len))

###############################
##LONG SHORT TERM MEMORY MODEL#
###############################
lstm_model = Sequential()
#Use CuDNNLSTM for better GPU performance
lstm_model.add(LSTM(units=Y.shape[1] 
                    , input_shape=X.shape
                    , return_sequences=True))
lstm_model.add(Dropout(0.2))
lstm_model.add(Dense(Y[1], activation='softmax'))


#lstm_model.add(LSTM(256, return_sequences=True))
#lstm_model.add(Dropout(0.2))
#lstm_model.add(LSTM(128))
#lstm_model.add(Dropout(0.2))
#lstm_model.add(Dense(Y.shape[1], activation='softmax'))

lstm_model.compile(loss='categorical_crossentropy', optimizer='adam')

start = np.random.randint(0, len(comments_tokenized) - 1)
pattern = comments_tokenized[start]
pattern = ['closer', 'than']
print("Random Seed:")
print([value for value in pattern])

lstm_model.predict(X[0], verbose=0)

for i in range(1000):
    x = np.reshape(pattern, (1, len(pattern), 1))
    prediction = lstm_model.predict([2.83096117], verbose=0)
    index = numpy.argmax(prediction)
    result = num_to_char[index]
    seq_in = [num_to_char[value] for value in pattern]

    sys.stdout.write(result)

    pattern.append(index)
    pattern = pattern[1:len(pattern)]

#Save model
#filepath = "model_weights_saved.hdf5"
#checkpoint = ModelCheckpoint(filepath, monitor='loss', verbose=1, save_best_only=True, mode='min')
#desired_callbacks = [checkpoint]
#
#lstm_model.fit(X, Y, epochs=4, batch_size=256, callbacks=desired_callbacks)

########################
##EXPLORATORY ANALYSIS##
########################

#Number of unique words appearing 2 or more times in the data
num_words = len(model.wv.vocab)


################
##APPLICATIONS##
################
    
    
def WordSearch(word):
    
    #Brings up statistics on specified words.
    
        #Frequency: Count of occurrence within and across all comments
    
        #CommentsContaining: Number of comments containing the word once or more
    
        #Related words: Words most related to the word of interest
            #Related words must be based on an established model
    
    #Frequency Across All Comments
    Freq = WordCount(' . '.join(comments_df['body']), word)
    
    #nComments containing the word
    query = f"select count(*) from comments where body like '% {word} %'"
    cursor = connection.cursor()
    cursor.execute(query)
    ncomments = cursor.fetchall()[0][0]
        
    #Top 3 Related Words
    similar_words = model.wv.most_similar(word)
    similar_words = ', '.join([y[0] for y in similar_words[0:3]])
    
    return {'Word': word
            , 'Frequency': Freq
            , 'nComments': ncomments
            , 'Top3Similar': similar_words}
#WordSearch('president')
             
                
                

