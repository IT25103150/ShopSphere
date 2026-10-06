package com.shopsphere.config;

import org.hibernate.boot.model.naming.CamelCaseToUnderscoresNamingStrategy;
import org.hibernate.boot.model.naming.Identifier;
import org.hibernate.engine.jdbc.env.spi.JdbcEnvironment;

/**
 * Columns are mapped camelCase -> snake_case (passwordHash -> password_hash) but table names are left exactly as
 * declared in @Table so they match the PascalCase tables created by database/01_schema.sql.
 */
public class TableNameKeepingNamingStrategy extends CamelCaseToUnderscoresNamingStrategy {
    @Override
    public Identifier toPhysicalTableName(Identifier logicalName, JdbcEnvironment jdbcEnvironment) {
        return logicalName;
    }
}
