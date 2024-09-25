const oracledb = require('oracledb');
const loadEnvFile = require('./utils/envUtil');
const envVariables = loadEnvFile('./.env');

// Database configuration setup. Ensure your .env file has the required database credentials.
const dbConfig = {
    user: envVariables.ORACLE_USER,
    password: envVariables.ORACLE_PASS,
    connectString: `${envVariables.ORACLE_HOST}:${envVariables.ORACLE_PORT}/${envVariables.ORACLE_DBNAME}`,
    poolMin: 1,
    poolMax: 3,
    poolIncrement: 1,
    poolTimeout: 60
};

// initialize connection pool
async function initializeConnectionPool() {
    try {
        await oracledb.createPool(dbConfig);
        console.log('Connection pool started');
    } catch (err) {
        console.error('Initialization error: ' + err.message);
    }
}

async function closePoolAndExit() {
    console.log('\nTerminating');
    try {
        await oracledb.getPool().close(10); // 10 seconds grace period for connections to finish
        console.log('Pool closed');
        process.exit(0);
    } catch (err) {
        console.error(err.message);
        process.exit(1);
    }
}

initializeConnectionPool();

process
    .once('SIGTERM', closePoolAndExit)
    .once('SIGINT', closePoolAndExit);


// ----------------------------------------------------------
// Wrapper to manage OracleDB actions, simplifying connection handling.
async function withOracleDB(action) {
    let connection;
    try {
        connection = await oracledb.getConnection(); // Gets a connection from the default pool 
        return await action(connection);
    } catch (err) {
        console.error(err);
        throw err;
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error(err);
            }
        }
    }
}


// ----------------------------------------------------------
// Core functions for database operations
// Modify these functions, especially the SQL queries, based on your project's requirements and design.
async function testOracleConnection() {
    return await withOracleDB(async (connection) => {
        return true;
    }).catch(() => {
        return false;
    });
}

// Query type satisfied: JOIN
async function getAttractions(province, city) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT attractionID, attractionName
             FROM TouristAttractions1 T1, TouristAttractions2 T2
             WHERE T1.latitude = T2.latitude AND T1.longitude = T2.longitude
             AND T1.province = :province AND T1.city = :city`,
            [province, city]
        );
        return result.rows;
    }).catch(() => {
        return [];
    })
}

// Query type satisfied: INSERTION
async function addAttraction(name, description, open, close, lat, long, category, province, city) {
    // First ensure that the foreign key is present in TouristAttractions1 table
    if (!(await checkTouristAttraction1(lat, long, province, city))) {
        await addTouristAttractions1(lat, long, province, city);
    }

    // Adding to TouristAttractions2
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `INSERT INTO TouristAttractions2 (attractionName, attractionDesc, category, openingHour, closingHour, latitude, longitude)
            VALUES(:attractionName, :attractionDesc, :category, :openingHour, :closingHour, :latitude, :longitude)`,
            [name, description, category, open, close, lat, long],
            { autoCommit: true }
        );
        return result.rowsAffected && result.rowsAffected > 0;
    }).catch((err) => {
        return false;
    })
}

// Check that the touristattraction1 exists
async function checkTouristAttraction1(lat, long, province, city) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT *
            FROM TouristAttractions1
            WHERE latitude = :latitude AND longitude = :longitude AND 
            province = :province AND city = :city`,
            [lat, long, province, city]
        );
        return (result.rows.length > 0);
    }).catch((err) => {
        return false;
    })
}

// Check that the touristattraction1 exists
async function checkTouristAttraction2(attractionID) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT *
            FROM TouristAttractions2
            WHERE attractionID = :id`,
            [attractionID]
        );
        return (result.rows.length > 0);
    }).catch((err) => {
        return false;
    })
}

async function addTouristAttractions1(lat, long, province, city) {
    // Ensure that province and city exist in Locations
    if (!(await checkLocation(province, city))) {
        await addLocation(province, city);
    }

    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `INSERT INTO TouristAttractions1
            VALUES(:latitude, :longitude, :province, :city)`,
            [lat, long, province, city],
            { autoCommit: true }
        );
        return result.rowsAffected && result.rowsAffected > 0;
    }).catch((err) => {
        return false;
    })
}

// Check that the location exists
async function checkLocation(province, city) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT *
            FROM Locations
            WHERE province = :province AND city = :city`,
            [province, city]
        );
        return (result.rows.length > 0);
    }).catch((err) => {
        return false;
    })
}

async function addLocation(province, city) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `INSERT INTO Locations
            VALUES(:province, :city)`,
            [province, city],
            { autoCommit: true }
        );
        return result.rowsAffected && result.rowsAffected > 0;
    }).catch((err) => {
        return false;
    })
}

// Update attraction
// first determine origianl lat and long
// update T2 with new lat and long if possible
// update T1 with new lat and long
// potentially update T2 with lat and long if it didnt work before

// Query type satisfied: UPDATE
async function updateAttraction(attractionID, name, description, open, close, lat, long, category, province, city) {
    const { oldLatitude, oldLongitude } = await determineLatLong(attractionID);
    if (!(await checkLocation(province, city))) {
        await addLocation(province, city);
    }
    const result1 = await nullifyT2(attractionID);
    const result2 = await updateT1(oldLatitude, oldLongitude, lat, long, province, city);
    const result3 = await updateT2(attractionID, name, description, open, close, lat, long, category);
    return true;
}

async function determineLatLong(attractionID) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT latitude, longitude
            FROM TouristAttractions1 T1
            WHERE EXISTS (
                SELECT 1
                FROM TouristAttractions2 T2
                WHERE T1.latitude = T2.latitude 
                AND T1.longitude = T2.longitude 
                AND T2.attractionID = :attractionID
            )
            `,
            [attractionID]
        );
        const [oldLatitude, oldLongitude] = result.rows[0];
        return { oldLatitude, oldLongitude };
    }).catch((err) => {
        throw new Error();
    })
}

async function nullifyT2(attractionID) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `UPDATE TouristAttractions2
            SET latitude = NULL, longitude = NULL
            WHERE attractionID = :attractionID
            `,
            [attractionID],
            { autoCommit: true }
        );
        return (result.rowsAffected && result.rowsAffected > 0);
    }).catch((err) => {
        return false;
    })
}

async function updateT1(oldLatitude, oldLongitude, lat, long, province, city) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `UPDATE TouristAttractions1
            SET latitude = :new_latitude, longitude = :new_longitude, province = :province, city = :city 
            WHERE latitude = :current_latitude AND longitude = :current_latitude
            `,
            [lat, long, province, city, oldLatitude, oldLongitude],
            { autoCommit: true }
        );
        return (result.rowsAffected && result.rowsAffected > 0);
    }).catch((err) => {
        return false;
    })
}

async function updateT2(attractionID, name, description, open, close, latitude, longitude, category) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `UPDATE TouristAttractions2
            SET attractionName = :name, attractionDesc = :description, openingHour = :open, closingHour = :close, 
            latitude = :latitude, longitude = :longitude, category = :category
            WHERE attractionID = :attractionID
            `,
            [name, description, open, close, latitude, longitude, category, attractionID],
            { autoCommit: true }
        );
        return (result.rowsAffected && result.rowsAffected > 0);
    }).catch((err) => {
        return false;
    })
}

// Query type satisfied: DELETE
async function deleteAttraction(attractionID) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `DELETE FROM TouristAttractions1 T1
            WHERE EXISTS (
                SELECT 1 
                FROM TouristAttractions2 T2
                WHERE T1.latitude = T2.latitude 
                AND T1.longitude = T2.longitude 
                AND T2.attractionID = :attractionID
            )
            `,
            [attractionID],
            { autoCommit: true }
        );
        return (result.rowsAffected && result.rowsAffected > 0);
    }).catch((err) => {
        return false;
    })
}

async function projectExperienceAttributes(id, toSelect) {
    return await withOracleDB(async (connection) => {

        //Pre defined hash_set to prevent sql injections in O(1) time
        selectorSet = new Set(['experienceID', 'experienceName', 'experienceDesc', 'company', 'price']);

        //Check
        toSelect.forEach(option => {
            if (!selectorSet.has(option)) {
                throw new Error(`Potential SQL Injection`);
            }
        });

        let parsedSelectorString = toSelect.join(', ');

        const query = `
        SELECT ${parsedSelectorString} 
        FROM ExperienceOffered
        WHERE attractionID = :id
        `;

        try {
            const result = await connection.execute(
                query,
                [id]
            );
            return result.rows;
        } catch (error) {
            throw error;
        }
    })
}


async function countAttractionsByCityAndProvince(province, city) {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT COUNT(*) AS attractionCount
            FROM TouristAttractions1
            WHERE province = :province AND city = :city`,
            [province, city]
        );
        return result.rows;
    }).catch(() => {
        return [];
    })
}

// Demo-ing the Query: Aggregation with HAVING
async function countAttractionsHaving() {
    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT province, city
            FROM TouristAttractions1
            GROUP BY city, province
            HAVING COUNT(*) > 2`
        );
        return result.rows;
    }).catch(() => {
        return [];
    })
}

// Demo-ing the Query: Nested Aggregation with GROUP BY
async function getAvgAttractionsPerProvince() {
    return await withOracleDB(async (connection) => {
        const query = `
        SELECT AVG(attractionCount) AS avgAttractionCount
        FROM (
            SELECT province, COUNT(*) AS attractionCount
            FROM TouristAttractions1
            GROUP BY province
        )
         `;
        try {
            const result = await connection.execute(query);
            return result.rows[0][0];
        } catch (error) {
            return null;
        }
    })
}

// Query type satisfied: SELECTION
async function applyPriceFilters(price, comparison) {
    return await withOracleDB(async (connection) => {
        let query;

        if (comparison == 'equals') {
            query =
                `SELECT experienceID, experienceName, price 
            FROM ExperienceOffered 
            WHERE price = :price`;
        } else if (comparison == 'larger') {
            query =
                `SELECT experienceID, experienceName, price 
            FROM ExperienceOffered 
            WHERE price >= :price`;
        } else if (comparison == 'smaller') {
            query =
                `SELECT experienceID, experienceName, price 
            FROM ExperienceOffered 
            WHERE price <= :price`;
        }

        try {
            const result = await connection.execute(
                query,
                [price]
            );
            return result.rows;
        } catch (error) {
            throw error;
        }
    })
}

// Query type satisfied: DIVISION
async function findCompletionist(attractionID) {
    // First ensure that the attraction exists, otherwise division will result in every user
    const result = await checkTouristAttraction2(attractionID);

    if (!result) {
        return [];
    }

    return await withOracleDB(async (connection) => {
        const result = await connection.execute(
            `SELECT userID, userName
            FROM UserProfile U
            WHERE NOT EXISTS 
                ((SELECT E.experienceID
                FROM ExperienceOffered E
                WHERE attractionID = :id)
                MINUS (SELECT B.experienceID
                    FROM Booking2 B
                    WHERE B.userID = U.userID))`,
            [attractionID]
        );
        return result.rows;
    }).catch(() => {
        return [];
    })
}

module.exports = {
    testOracleConnection,
    getAttractions,
    addAttraction,
    deleteAttraction,
    projectExperienceAttributes,
    applyPriceFilters,
    countAttractionsByCityAndProvince,
    countAttractionsHaving,
    getAvgAttractionsPerProvince,
    findCompletionist,
    updateAttraction
};