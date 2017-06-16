// Get Tweet Information
WITH
  'https://api.twitter.com/1.1/statuses/show.json?id=' as url,
  {token} as token
MATCH (t:Tweet)
WHERE NOT (t)<-[:TWEETED]-()
CALL apoc.load.jsonParams(url + t.id_str, {Authorization:"Bearer "+token},null) yield value

WITH
  value AS status,
  value.user AS user,
  value.entities AS entities

WITH status, user, entities,
  CASE WHEN status.quoted_status_id IS NOT NULL THEN [toString(status.quoted_status_id)] ELSE [] END AS quoted,
  CASE WHEN status.retweeted_status IS NOT NULL THEN [status.retweeted_status.id_str] ELSE [] END AS retweeted,
  CASE WHEN status.in_reply_to_status_id_str IS NOT NULL THEN [status.in_reply_to_status_id_str] ELSE [] END AS in_reply_to,
  CASE WHEN status.place IS NOT NULL THEN [status.place] ELSE [] END AS places

// Create Tweet
MERGE (t:Tweet {id_str:status.id_str})
SET t.text=status.text,t.created_at=status.created_at,t.retweet_count=status.retweet_count, t.favorite_count=status.favorite_count

// Create Author
MERGE (u:User {screen_name:user.screen_name})
SET u.name = user.name, u.friends_count = user.friends_count, u.followers_count = user.followers_count, u.picture=user.profile_image_url

MERGE (u)-[:TWEETED]->(t)

// Create Hashtags
FOREACH (h in entities.hashtags | MERGE (ht:Hashtag {name:h.text}) MERGE (t)-[:MENTIONS_HASHTAG]->(ht))

// Mentions
FOREACH (m in entities.user_mentions | MERGE (mu:User {screen_name:m.screen_name})  MERGE (t)-[:MENTIONS_USER]->(mu))

// URLs
FOREACH (m in entities.urls | MERGE (mu:URL {url:m.url})  MERGE (t)-[:MENTIONS_URL]->(mu))

// Quoted Status?
FOREACH (s_id_str in quoted | MERGE (qt:Tweet {id_str
:s_id_str}) MERGE (t)-[:QUOTES_TWEET]->(qt) )

// Retweeted Status
FOREACH (s_id_str in retweeted | MERGE (qt:Tweet {id_str:s_id_str}) MERGE (t)-[:RETWEETS_TWEET]->(qt) )

// Reply to
FOREACH (s_id_str in in_reply_to | MERGE (qt:Tweet {id_str:s_id_str}) MERGE (t)-[:IN_REPLY_TO]->(qt) )

// Place
FOREACH (place in places | MERGE (p:Place {name:place.full_name}) SET p.country = place.country, p.id = place.id MERGE (t)-[:TWEETED_IN]->(p))

RETURN *