USE SSISDB
GO

SET NOCOUNT ON;

SELECT prj.[name] AS project_name,
       -- Parameter Info
       CASE par.object_type
            WHEN 20 THEN 'Project'
            WHEN 30 THEN 'Package'
       END AS object_level,
       par.[object_name],
       par.parameter_name,
       par.data_type,
       par.[required],
       par.sensitive,
       par.[description],
       -- Explicit value source
       CASE WHEN par.sensitive = 1 THEN 'SENSITIVE'
            WHEN par.value_type = 'R' AND ev.value IS NOT NULL THEN 'ENVIRONMENT'
            WHEN par.value_type = 'R' AND ev.value IS NULL THEN 'MISSING ENV VARIABLE'
            WHEN par.value_type = 'V' THEN 'LITERAL'
            WHEN par.value_set = 0 THEN 'DEFAULT'
            ELSE 'UNKNOWN'
       END AS value_source,
       -- Resolved value (masked for sensitive parameters)
       CASE WHEN par.sensitive = 1 THEN '***SENSITIVE***'
            WHEN par.value_type = 'R' THEN ISNULL(ev.[value], 'MISSING ENV VARIABLE')
            WHEN par.value_type = 'V' THEN par.default_value
            WHEN par.value_set = 0 THEN par.design_default_value
       END AS resolved_value,
       -- Environment Info
       er.environment_folder_name,
       er.environment_name,
       IIF(par.value_type <> 'R' OR par.referenced_variable_name IS NULL, 'NO', 'YES') AS is_environment_driven,
       ev.[name] AS environment_variable_name,
       ev.[value] AS environment_value
  FROM SSISDB.catalog.object_parameters AS par
       INNER JOIN SSISDB.catalog.projects AS prj ON par.project_id = prj.project_id
       LEFT JOIN SSISDB.catalog.environment_references er ON prj.project_id = er.project_id
       LEFT JOIN SSISDB.catalog.folders f ON f.[name] = er.environment_folder_name
       LEFT JOIN SSISDB.catalog.environments env ON env.[name] = er.environment_name
             AND env.folder_id = f.folder_id
       LEFT JOIN SSISDB.catalog.environment_variables ev ON ev.environment_id = env.environment_id
             AND par.referenced_variable_name = ev.[name]
 WHERE 1 = 1
   AND par.object_type = 20
   AND prj.[name] = 'Test'
   AND er.environment_name = 'UAT'
 ORDER BY project_name, [object_name], data_type;