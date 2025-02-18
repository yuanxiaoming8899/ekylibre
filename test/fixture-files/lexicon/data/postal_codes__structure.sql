DROP TABLE IF EXISTS registered_postal_codes;

        CREATE TABLE registered_postal_codes (
          id character varying PRIMARY KEY NOT NULL,
          country character varying NOT NULL,
          code character varying NOT NULL,
          city_name character varying NOT NULL,
          postal_code character varying NOT NULL,
          city_delivery_name character varying,
          city_delivery_detail character varying,
          city_centroid postgis.geometry(Point,4326),
          city_shape postgis.geometry(MultiPolygon, 4326)
      );

        CREATE INDEX registered_postal_codes_country ON registered_postal_codes(country);
        CREATE INDEX registered_postal_codes_city_name ON registered_postal_codes(city_name);
        CREATE INDEX registered_postal_codes_postal_code ON registered_postal_codes(postal_code);
        CREATE INDEX registered_postal_codes_centroid ON registered_postal_codes USING GIST (city_centroid);
        CREATE INDEX registered_postal_codes_shape ON registered_postal_codes USING GIST (city_shape);
