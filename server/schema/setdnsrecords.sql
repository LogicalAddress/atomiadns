CREATE OR REPLACE FUNCTION SetDnsRecords(
	zonename varchar,
	records varchar[][]
) RETURNS void AS $$
DECLARE
	record_label_id bigint;
	record_zone_id bigint;
BEGIN
	FOR i IN array_lower(records, 1) .. array_upper(records, 1) LOOP

		SELECT label.id INTO record_label_id FROM zone INNER JOIN label ON zone.id = zone_id WHERE name = zonename AND label = records[i][2];
		IF NOT FOUND THEN
			SELECT id INTO record_zone_id FROM zone WHERE name = zonename;
			IF NOT FOUND THEN
				RAISE EXCEPTION 'zone % not found', zonename;
			ELSE
				INSERT INTO label (zone_id, label) VALUES (record_zone_id, records[i][2]);
				record_label_id := currval('label_id_seq');
			END IF;
		END IF;

		DELETE FROM record WHERE label_id = record_label_id AND type = records[i][5] AND class = records[i][3]::dnsclass;
	END LOOP;

	-- Lets do it in the KISS way for simplicity by duplicating the loop, so that we don't have to
	-- care about storing label_id's.

	FOR i IN array_lower(records, 1) .. array_upper(records, 1) LOOP

		SELECT label.id INTO record_label_id FROM zone INNER JOIN label ON zone.id = zone_id WHERE name = zonename AND label = records[i][2];
		IF NOT FOUND THEN
			SELECT id INTO record_zone_id FROM zone WHERE name = zonename;
			IF NOT FOUND THEN
				RAISE EXCEPTION 'zone % not found', zonename;
			ELSE
				INSERT INTO label (zone_id, label) VALUES (record_zone_id, records[i][2]);
				record_label_id := currval('label_id_seq');
			END IF;
		END IF;

		INSERT INTO record (label_id, ttl, class, type, rdata) VALUES (record_label_id, 
					records[i][4]::bigint, records[i][3]::dnsclass,  records[i][5],  records[i][6]);
	END LOOP;
END; $$ LANGUAGE plpgsql;
