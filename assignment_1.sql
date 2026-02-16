select
    *
from read_json("/Users/dkalchenko/Downloads/tvs.json", sample_size = 158677655);

create or replace table TVSeries as
select
    id,
    name,
    in_production,
    status,
    original_language,
    country,
    cast(json_value(created, '$.id') as int64) as created_by_id,
    trim(both '""' from json_value(created, '$.name')) as created_by,
    cast(nullif(first_air_date, '') as date) as first_air_date,
    try_cast(last_air_date as date) as last_air_date,
    number_of_episodes,
    number_of_seasons,
    trim(both '""' from json_value(production, '$.name')) as prod_comp_name,
    trim(both '""' from json_value(production, '$.origin_country')) as prod_origin_country,
    json_value(production, '$._id.oid') as prod_comp_id,
    cast(json_value(genre, '$.id') as int64) as genre_id,
    trim(both '""' from json_value(genre, '$.name')) as genre_name,
    round(vote_average, 2) as vote_average,
    vote_count,
    round(popularity, 2) as popularity
from read_json("/Users/dkalchenko/Downloads/tvs.json", sample_size = 158677655) as tvs
cross join unnest(origin_country) as t1(country)
cross join unnest(created_by) as t2(created)
cross join unnest(production_companies) as t3(production)
cross join unnest(genres) as t4(genre);

-- Sample:
select * from TVSeries
limit 100;

--ANALYTICAL INSIGHTS
-- Top shows by avg vote per genre
with distincts as (
    select distinct
        name as show_name,
        vote_average,
        genre_name,
        vote_count
    from TVSeries
    where vote_count > 10
)
select
    genre_name,
    show_name,
    vote_average,
    vote_count,
    round(avg(vote_average) over(partition by genre_name), 2) as avg_per_genre,
    rank() over(partition by genre_name order by vote_average desc) as rank
from distincts
qualify rank <= 5;
-- Result Sample:
-- Sci-Fi & Fantasy,Mine Three-Body,9.31,16,7.35,1
-- Sci-Fi & Fantasy,Sonic Mania Adventures,9.3,12,7.35,2
-- Sci-Fi & Fantasy,The Legend of Luo Xiaohei,9.27,11,7.35,3
-- Sci-Fi & Fantasy,O Auto da Compadecida,9.14,50,7.35,4
-- Sci-Fi & Fantasy,Someday or One Day,9.03,29,7.35,5
-- Kids,Gortimer Gibbon's Life on Normal Street,9.27,11,7.32,1
-- Kids,Wallace & Gromit,9.2,13,7.32,2
-- Kids,Dynomutt: Dog Wonder,9.15,54,7.32,3
-- Kids,The Richie Rich/Scooby-Doo Show and Scrappy Too!,9.1,28,7.32,4
-- Kids,The Rocketeer,8.92,12,7.32,5
-- Music,Un paso adelante,5.58,19,5.58,1
-- War & Politics,For the Sake of the Republic,9.5,11,7.39,1
-- War & Politics,The Romance of the Three Kingdoms,9.2,15,7.39,2
-- War & Politics,Drawing Sword,9,19,7.39,3
-- War & Politics,"The Long, Long Holiday",8.73,11,7.39,4
-- War & Politics,Ekaterina,8.73,15,7.39,4
-- Family,Sonic Mania Adventures,9.3,12,7.37,1
-- Family,Gortimer Gibbon's Life on Normal Street,9.27,11,7.37,2
-- Family,Dynomutt: Dog Wonder,9.15,54,7.37,3
-- Family,My Own Swordsman,9.11,33,7.37,4

-- This query allows us to identify the best rated shows per each genre in descending order.
-- We can also see how many votes are taken into this statistics to understand how representative the rate is.


-- Avg production company popularity with their top 1 show
with top_show as (
    select
        prod_comp_name,
        name as show_name,
        popularity as top_show_popularity,
        row_number() over(partition by prod_comp_name order by popularity desc) as rn
    from TVSeries
    qualify rn = 1
),
avg_by_company as (
    select
        prod_comp_name,
        round(avg(popularity), 2) as avg_popularity
    from TVSeries
    group by prod_comp_name
)
select
    ac.*,
    ts.show_name,
    ts.top_show_popularity
from avg_by_company ac
left join top_show ts
on ac.prod_comp_name = ts.prod_comp_name
order by avg_popularity desc
limit 50;

-- Result Sample:
-- Cockcrow Entertainment & Shaika Films,1276.25,Ghum Hai Kisi Ke Pyaar Mein,1276.25
-- Rabbit Gate,1104.98,Chichi-iro Toiki,1104.98
-- Cockcrow Productions and Shaika Films,836.46,Teri Meri Doriyaan,2082.19
-- SOL Production,611.44,Chashni,1828.66
-- PlayStation Productions,610.8,The Last of Us,610.8
-- Naughty Dog,610.8,The Last of Us,610.8
-- Exile Content,545.21,VGLY,1089.33
-- Fairview Entertainment,520.2,The Mandalorian,520.2
-- Toluca Pictures,456.37,Wednesday,456.37
-- ufotable,452.87,Demon Slayer: Kimetsu no Yaiba,452.87
-- Word Games,431.41,The Last of Us,610.8
-- Mark Goodson Productions LLC,422.19,The Price Is Right,422.19
-- Price Productions,422.19,The Price Is Right,422.19
-- Mark Goodson Television Productions,422.19,The Price Is Right,422.19
-- Bunny Walker,370.81,Ane wa Yanmama Junyuu-chuu,1013.01
-- 3AD,370.02,The Good Doctor,370.02
-- Markíza Slovakia,363.31,Mama na prenájom,995.33
-- Buji Productions,351.95,BEEF,351.95
-- Domo Arigato Productions,351.95,BEEF,351.95
-- Bugsy Bell Productions,351.95,BEEF,351.95

-- This query allows us to find out the most "popular" production companies based on the popularity of their shows.
-- We can also see its most popular show and its popularity score. Therefore, we can compare how the average popularity differs
-- from the most popular show.

-- for visualisation
copy (
   with top_show as (
    select
        prod_comp_name,
        name as show_name,
        popularity as top_show_popularity,
        row_number() over(partition by prod_comp_name order by popularity desc) as rn
    from TVSeries
    qualify rn = 1
),
avg_by_company as (
    select
        prod_comp_name,
        round(avg(popularity), 2) as avg_popularity
    from TVSeries
    group by prod_comp_name
)
select
    ac.*,
    ts.show_name,
    ts.top_show_popularity
from avg_by_company ac
left join top_show ts
on ac.prod_comp_name = ts.prod_comp_name
order by avg_popularity desc
limit 50
)
TO 'top_productions.csv' (HEADER, DELIMITER ',');