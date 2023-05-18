import { BIGINT, STRING, DATE } from 'sequelize';
import {logger} from "./index.js";

export default async function bootstrap(sequelize) {

    try {
        await sequelize.authenticate();
        logger.info('Connection to the database has been established successfully.');
    } catch (error) {
        logger.error('Unable to connect to the database:', error);
    }

    const User = sequelize.define('users', {
        id: {
            type: BIGINT,
            primaryKey: true,
            autoIncrement: true,
        },
        first_name: {
            type: STRING,
            allowNull: false,
        },
        last_name: {
            type: STRING,
            allowNull: false,
        },
        password: {
            type: STRING,
            allowNull: false,
        },
        username: {
            type: STRING,
            allowNull: false,
            unique: true,
        },
        account_created: {
            type: DATE,
            allowNull: false,
        },
        account_updated: {
            type: DATE,
        },
    }, {
        tableName: 'users',
        timestamps: false,
    });

    const Product = sequelize.define('products', {
        id: {
            type: BIGINT,
            primaryKey: true,
            autoIncrement: true,
        },
        name: {
            type: STRING,
            allowNull: false,
        },
        description: {
            type: STRING,
            allowNull: false,
        },
        SKU: {
            type: STRING,
            allowNull: false,
            unique: true,
        },
        manufacturer: {
            type: STRING,
            allowNull: false,
        },
        quantity: {
            type: BIGINT,
            allowNull: false,
        },
        date_added: {
            type: DATE,
            allowNull: false,
        },
        date_last_updated: {
            type: DATE,
        },
        owner_user_id: {
            type: BIGINT,
            allowNull: false,
        },
    }, {
        tableName: 'products',
        timestamps: false,
    });

    const Image = sequelize.define('images', {
        image_id: {
            type: BIGINT,
            primaryKey: true,
            autoIncrement: true,
        },
        product_id: {
            type: BIGINT,
            allowNull: false,
        },
        file_name: {
            type: STRING,
            allowNull: false,
        },
        date_created: {
            type: DATE,
            allowNull: false,
        },
        s3_bucket_path: {
            type: STRING,
            allowNull: false,
        },
    }, {
        tableName: 'images',
        timestamps: false,
    });

    // Check if the database exists, if not, create it
    try {
        await sequelize.sync({ force: false });
        logger.info('Tables have been successfully created/updated.');
    } catch (error) {
        logger.error('An error occurred while creating/updating the tables:', error);
    }
};




