// Get Retweets
WITH
  'https://api.twitter.com/1.1/statuses/retweets.json?id=' as url,
  {token} as token
MATCH (t:Tweet)
WITH url, token, t, COALESCE(t.retweets_updated_at, 0) as retweets_updated_at
ORDER BY retweets_updated_at DESC
LIMIT 1
CALL apoc.load.jsonParams(url + t.id_str, {Authorization:"Bearer "+token},null) yield value

WITH
  value AS status,
  value.user AS user,
  value.entities AS entities

// Create Tweet
MERGE (t:Tweet {id:status.id_str})
SET t.text=status.text,t.created_at=status.created_at,t.retweet_count=status.retweet_count, t.favorite_count=status.favorite_count

MERGE (u:User {screen_name:user.screen_name})
