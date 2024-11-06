from googleapiclient.discovery import build
import re
from operator import itemgetter
import pandas as pd

API_KEY = "AIzaSyBN5zQeMwhyxOB2RTZO-ApMZADfOVfWyjA"

# Function to get the video id
def get_video_id():
    regExp = r"/ ^.*((youtu.be\ /) | (v\ /) | (\ / u\ / \w\ /) | (embed\ /) | (watch\?))\??v?=?([ ^  # \&\?]*).*/"
    video_id = input("VideoId: ")

# Build the YouTube client
youtube = build('youtube', 'v3', developerKey=API_KEY)


# Function to get replies for a specific comment
def get_replies(youtube, parent_id, video_id):  # Added video_id as an argument
    replies = []
    next_page_token = None

    while True:
        reply_request = youtube.comments().list(
            part="snippet",
            parentId=parent_id,
            textFormat="plainText",
            maxResults=100,
            pageToken=next_page_token
        )
        reply_response = reply_request.execute()

        for item in reply_response['items']:
            comment = item['snippet']
            replies.append({
                'Timestamp': comment['publishedAt'],
                'Username': comment['authorDisplayName'],
                'VideoID': video_id,
                'Comment': comment['textDisplay'],
                'Date': comment['updatedAt'] if 'updatedAt' in comment else comment['publishedAt']
            })

        next_page_token = reply_response.get('nextPageToken')
        if not next_page_token:
            break

    return replies


# Function to get all comments (including replies) for a single video
def get_comments_for_video(youtube, video_id):
    all_comments = []
    next_page_token = None

    while True:
        comment_request = youtube.commentThreads().list(
            part="snippet",
            videoId=video_id,
            pageToken=next_page_token,
            textFormat="plainText",
            maxResults=100
        )
        comment_response = comment_request.execute()

        for item in comment_response['items']:
            top_comment = item['snippet']['topLevelComment']['snippet']
            all_comments.append({
                'Timestamp': top_comment['publishedAt'],
                'Username': top_comment['authorDisplayName'],
                'VideoID': video_id,  # Directly using video_id from function parameter
                'Comment': top_comment['textDisplay'],
                'Date': top_comment['updatedAt'] if 'updatedAt' in top_comment else top_comment['publishedAt']
            })

            # Fetch replies if there are any
            if item['snippet']['totalReplyCount'] > 0:
                all_comments.extend(get_replies(youtube, item['snippet']['topLevelComment']['id'], video_id))

        next_page_token = comment_response.get('nextPageToken')
        if not next_page_token:
            break

    return all_comments


# List to hold all comments from all videos
all_comments = []

video_comments = get_comments_for_video(youtube, video_id)
all_comments.extend(video_comments)

# Create DataFrame
comments_df = pd.DataFrame(all_comments)

sorted_comments = sorted(all_comments, key=itemgetter('Date', 'Username'), reverse=True)
print(all_comments)
print()
print(f"{sorted_comments}\n\n")

for _ in sorted_comments:
    print(_["Comment"])
