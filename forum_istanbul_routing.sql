/* --PostGIS eklentisinin veritabanına kurulması
CREATE EXTENSION postgis;
SELECT postgis_full_version();

--pgRouting eklentisinin veritabanına kurulması
CREATE EXTENSION pgRouting;

SELECT * FROM "transition";
SELECT * FROM "transition_noded";
SELECT * FROM "transition_noded_vertices_pgr";


--Tabloya başlangıç ve hedef kolonlarının eklenmesi
ALTER TABLE "transition" ADD COLUMN "source" int4;
ALTER TABLE "transition" ADD COLUMN "target" int4;
ALTER TABLE "transition_noded" ADD COLUMN "distance" FLOAT;
ALTER TABLE "transition_noded" ADD COLUMN "name" varchar;
UPDATE "transition_noded" SET "name"=transition."name" FROM "transition" WHERE transition_noded."old_id"=transition."id";

ALTER TABLE "transition"
 ALTER COLUMN "the_geom" TYPE geometry(LineString,4326)
  USING ST_LineMerge("the_geom"); */
  
SELECT pgr_nodeNetwork('transition',0.00001);
SELECT pgr_createTopology('transition_noded',0.00001);
UPDATE "transition_noded" SET "distance"=ST_Length(ST_Transform("the_geom",4326)::geography)

ALTER TABLE "transition_noded" ADD COLUMN "x1" double precision;
ALTER TABLE "transition_noded" ADD COLUMN "y1" double precision;
ALTER TABLE "transition_noded" ADD COLUMN "x2" double precision;
ALTER TABLE "transition_noded" ADD COLUMN "y2" double precision;

UPDATE "transition_noded" SET "x1" = ST_x(ST_startpoint("the_geom"));
UPDATE "transition_noded" SET "y1" = ST_y(ST_startpoint("the_geom"));

UPDATE "transition_noded" SET "x2" = ST_x(ST_endpoint("the_geom"));
UPDATE "transition_noded" SET "y2" = ST_y(ST_endpoint("the_geom"));

UPDATE "transition_noded" SET "x1" = ST_x(ST_PointN("the_geom", 1));
UPDATE "transition_noded" SET "y1" = ST_y(ST_PointN("the_geom", 1));

UPDATE "transition_noded" SET "x2" = ST_x(ST_PointN("the_geom", ST_NumPoints("the_geom")));
UPDATE "transition_noded" SET "y2" = ST_y(ST_PointN("the_geom", ST_NumPoints("the_geom")));

SELECT * FROM pgr_astar('SELECT id, source, target, distance as cost,x1,y1,x2,y2 FROM transition_noded',210,225,false)
SELECT * FROM pgr_dijkstra('SELECT id, source, target, distance as cost  FROM transition_noded',210,225,false)

SELECT
 min(r."seq") AS seq,
 e."old_id" AS id,
 sum(e."distance") AS distance,
ST_Collect(e."the_geom") AS geom 
 FROM pgr_dijkstra('SELECT id,source,target,distance AS cost 
 FROM transition_noded',210,225,false) AS r,"transition_noded" AS e 
 WHERE r."edge"=e."id" GROUP BY e."old_id"
