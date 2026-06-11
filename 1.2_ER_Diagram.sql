USE UniHospital;
GO

SELECT
    fk.name AS ForeignKeyName,
    parent_table.name AS ChildTable,
    parent_column.name AS ChildColumn,
    referenced_table.name AS ParentTable,
    referenced_column.name AS ParentColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables parent_table
    ON fkc.parent_object_id = parent_table.object_id
INNER JOIN sys.columns parent_column
    ON fkc.parent_object_id = parent_column.object_id
   AND fkc.parent_column_id = parent_column.column_id
INNER JOIN sys.tables referenced_table
    ON fkc.referenced_object_id = referenced_table.object_id
INNER JOIN sys.columns referenced_column
    ON fkc.referenced_object_id = referenced_column.object_id
   AND fkc.referenced_column_id = referenced_column.column_id
ORDER BY
    parent_table.name,
    fk.name;