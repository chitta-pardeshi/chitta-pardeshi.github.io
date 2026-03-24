-- EAV Schema: Tables

CREATE TABLE sys_tenants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    org_id TEXT UNIQUE NOT NULL
);

CREATE TABLE sys_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL DEFAULT 0,
    key TEXT NOT NULL,
    value TEXT,
    UNIQUE(tenant_id, key)
);

CREATE TABLE sys_roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    parent_role_id INTEGER, -- For hierarchy (Manager sees Subordinate data)
    name TEXT NOT NULL,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (parent_role_id) REFERENCES sys_roles(id)
);

CREATE TABLE sys_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id)
);

CREATE TABLE sys_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    password_hash TEXT,
    is_active BOOLEAN DEFAULT 1,
    role_id INTEGER REFERENCES sys_roles(id),
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (profile_id) REFERENCES sys_profiles(id)
);

CREATE TABLE sys_objects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    api_name TEXT NOT NULL,
    label TEXT NOT NULL,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    UNIQUE(tenant_id, api_name)
);

CREATE TABLE sys_record_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL,
    api_name TEXT NOT NULL,
    label TEXT NOT NULL,
    FOREIGN KEY (object_id) REFERENCES sys_objects(id),
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    UNIQUE(tenant_id, object_id, api_name)
);

CREATE TABLE sys_fields (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    object_id INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL,
    api_name TEXT NOT NULL,
    label TEXT NOT NULL,
    data_type TEXT NOT NULL, -- 'TEXT', 'NUMERIC', 'DATE', 'PICKLIST', 'LOOKUP'
    target_object_id INTEGER REFERENCES sys_objects(id), -- for LOOKUP fields: the object being pointed to
    relationship_name TEXT, -- reverse lookup label on parent object (e.g., "Contacts", "Opportunities")
    FOREIGN KEY (object_id) REFERENCES sys_objects(id),
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    UNIQUE(tenant_id, object_id, api_name)
);

CREATE TABLE sys_record_type_fields (
    record_type_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    is_required BOOLEAN DEFAULT 0,
    is_read_only BOOLEAN DEFAULT 0,
    default_value TEXT,
    PRIMARY KEY (record_type_id, field_id),
    FOREIGN KEY (record_type_id) REFERENCES sys_record_types(id) ON DELETE CASCADE,
    FOREIGN KEY (field_id) REFERENCES sys_fields(id) ON DELETE CASCADE
);

CREATE TABLE sys_field_picklist_values (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    field_id INTEGER NOT NULL,
    value TEXT NOT NULL,
    label TEXT NOT NULL,
    is_active BOOLEAN DEFAULT 1,
    display_order INTEGER,
    UNIQUE (field_id, value),
    FOREIGN KEY (field_id) REFERENCES sys_fields(id) ON DELETE CASCADE
);

CREATE TABLE sys_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL,
    session_token TEXT UNIQUE NOT NULL,
    expires_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES sys_users(id),
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id)
);

CREATE TABLE sys_object_perms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL,
    object_id INTEGER NOT NULL,
    can_read BOOLEAN DEFAULT 0,
    can_create BOOLEAN DEFAULT 0,
    can_edit BOOLEAN DEFAULT 0,
    can_delete BOOLEAN DEFAULT 0,
    view_all BOOLEAN DEFAULT 0,
    modify_all BOOLEAN DEFAULT 0,
    FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (object_id) REFERENCES sys_objects(id) ON DELETE CASCADE,
    UNIQUE(profile_id, object_id)
);

CREATE TABLE sys_field_perms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    can_read BOOLEAN DEFAULT 0,
    can_edit BOOLEAN DEFAULT 0,
    FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (field_id) REFERENCES sys_fields(id) ON DELETE CASCADE,
    UNIQUE(profile_id, field_id)
);

CREATE TABLE sys_apps (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    api_name TEXT NOT NULL,
    label TEXT NOT NULL,
    description TEXT,
    nav_type TEXT DEFAULT 'Standard',
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id)
);

CREATE TABLE sys_tabs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    object_id INTEGER,
    api_name TEXT NOT NULL,
    label TEXT NOT NULL,
    icon_name TEXT,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (object_id) REFERENCES sys_objects(id)
);

CREATE TABLE sys_app_tabs (
    app_id INTEGER NOT NULL,
    tab_id INTEGER NOT NULL,
    sequence INTEGER NOT NULL,
    PRIMARY KEY (app_id, tab_id),
    FOREIGN KEY (app_id) REFERENCES sys_apps(id),
    FOREIGN KEY (tab_id) REFERENCES sys_tabs(id)
);

CREATE TABLE sys_app_perms (
    profile_id INTEGER NOT NULL,
    app_id INTEGER NOT NULL,
    is_visible BOOLEAN DEFAULT 1,
    is_default BOOLEAN DEFAULT 0,
    PRIMARY KEY (profile_id, app_id),
    FOREIGN KEY (profile_id) REFERENCES sys_profiles(id),
    FOREIGN KEY (app_id) REFERENCES sys_apps(id)
);

CREATE TABLE sys_layouts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    object_id INTEGER NOT NULL,
    layout_type TEXT CHECK(layout_type IN ('LIST', 'FORM', 'SEARCH', 'FILTER', 'LEFTFILTER')),
    name TEXT NOT NULL,
    is_default BOOLEAN DEFAULT 0,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (object_id) REFERENCES sys_objects(id)
);

CREATE TABLE sys_layout_fields (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    layout_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    sequence INTEGER NOT NULL,
    is_required BOOLEAN DEFAULT 0,
    is_read_only BOOLEAN DEFAULT 0,
    FOREIGN KEY (layout_id) REFERENCES sys_layouts(id),
    FOREIGN KEY (field_id) REFERENCES sys_fields(id)
);

CREATE TABLE sys_layout_assignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    profile_id INTEGER NOT NULL,
    record_type_id INTEGER NOT NULL,
    layout_id INTEGER NOT NULL,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (profile_id) REFERENCES sys_profiles(id),
    FOREIGN KEY (record_type_id) REFERENCES sys_record_types(id),
    FOREIGN KEY (layout_id) REFERENCES sys_layouts(id),
    UNIQUE(profile_id, record_type_id)
);

CREATE TABLE data_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    object_id INTEGER NOT NULL,
    record_type_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by_id INTEGER,
    last_modified_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_modified_by_id INTEGER,
    system_modstamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT 0,
    owner_id INTEGER NOT NULL REFERENCES sys_users(id),
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (object_id) REFERENCES sys_objects(id)
);

CREATE TABLE val_text (
    record_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    value TEXT,
    PRIMARY KEY (record_id, field_id),
    FOREIGN KEY (record_id) REFERENCES data_records(id) ON DELETE CASCADE
);

CREATE TABLE val_numeric (
    record_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    value REAL,
    PRIMARY KEY (record_id, field_id),
    FOREIGN KEY (record_id) REFERENCES data_records(id) ON DELETE CASCADE
);

CREATE TABLE val_lookup (
    record_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    target_record_id INTEGER NOT NULL,
    PRIMARY KEY (record_id, field_id),
    FOREIGN KEY (record_id) REFERENCES data_records(id) ON DELETE CASCADE,
    FOREIGN KEY (target_record_id) REFERENCES data_records(id),
    FOREIGN KEY (field_id) REFERENCES sys_fields(id)
);

CREATE TABLE val_embedding (
    record_id INTEGER PRIMARY KEY,
    model TEXT NOT NULL,
    embedding TEXT NOT NULL,  -- JSON array of floats e.g. '[0.12, -0.34, ...]'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (record_id) REFERENCES data_records(id) ON DELETE CASCADE
);

CREATE TABLE embed_queue (
    record_id INTEGER PRIMARY KEY,
    queued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    attempts INTEGER DEFAULT 0,
    last_error TEXT,
    FOREIGN KEY (record_id) REFERENCES data_records(id) ON DELETE CASCADE
);

CREATE TABLE sys_indexes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    object_id INTEGER NOT NULL,
    api_name TEXT NOT NULL,
    label TEXT,
    is_unique BOOLEAN DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    description TEXT,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (object_id) REFERENCES sys_objects(id),
    UNIQUE(tenant_id, object_id, api_name)
);

CREATE TABLE sys_index_fields (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    index_id INTEGER NOT NULL,
    field_id INTEGER NOT NULL,
    sequence INTEGER NOT NULL DEFAULT 1,
    sort_direction TEXT DEFAULT 'ASC' CHECK(sort_direction IN ('ASC', 'DESC')),
    FOREIGN KEY (index_id) REFERENCES sys_indexes(id) ON DELETE CASCADE,
    FOREIGN KEY (field_id) REFERENCES sys_fields(id) ON DELETE CASCADE,
    UNIQUE(index_id, field_id)
);

-- ── Rules Engine ──────────────────────────────────────────────────────────

CREATE TABLE sys_rule_entry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,

    -- Polymorphic parent: sys_objects, sys_fields, or sys_rule_entry
    parent_meta_name TEXT NOT NULL,
    parent_meta_id INTEGER NOT NULL,

    name TEXT NOT NULL,
    description TEXT,
    rule_type TEXT NOT NULL CHECK(rule_type IN (
        'GROUP', 'VALIDATION', 'STATE_TRANSITION',
        'FIELD_UPDATE', 'ASSIGNMENT', 'ESCALATION', 'AI_ACTION', 'DATA_QUALITY'
    )),
    trigger_event TEXT NOT NULL CHECK(trigger_event IN (
        'ON_CREATE', 'ON_UPDATE', 'ON_FIELD_CHANGE', 'ON_STAGE_CHANGE',
        'ON_TIME', 'ON_DEMAND', 'ON_PARENT_COMPLETE'
    )),
    target_field_id INTEGER,
    criteria_json TEXT,
    action_json TEXT,
    activity_subject TEXT,
    activity_priority TEXT DEFAULT 'Medium' CHECK(activity_priority IN ('High', 'Medium', 'Low')),
    execution_order INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT 1,
    requires_ai BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by_id INTEGER,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (target_field_id) REFERENCES sys_fields(id),
    FOREIGN KEY (created_by_id) REFERENCES sys_users(id),
    UNIQUE(tenant_id, parent_meta_name, parent_meta_id, name)
);

CREATE INDEX idx_rule_entry_parent ON sys_rule_entry(parent_meta_name, parent_meta_id)
    WHERE is_active = 1;

-- ── Prompt Library ─────────────────────────────────────────────────────

CREATE TABLE sys_prompts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'CUSTOM' CHECK(category IN (
        'SYSTEM',
        'RULE',
        'TEMPLATE',
        'CUSTOM'
    )),
    object_id INTEGER,
    system_prompt TEXT,
    user_prompt TEXT NOT NULL,
    model TEXT,
    max_tokens INTEGER,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by_id INTEGER,
    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (object_id) REFERENCES sys_objects(id),
    FOREIGN KEY (created_by_id) REFERENCES sys_users(id),
    UNIQUE(tenant_id, name)
);

-- ── Operational Data ─────────────────────────────────────────────────────

CREATE TABLE op_activities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,

    -- Polymorphic parent: object + record + optional field
    parent_object_id INTEGER NOT NULL,
    parent_record_id INTEGER NOT NULL,
    parent_field_id INTEGER,

    subject TEXT NOT NULL,
    body TEXT,
    type TEXT NOT NULL CHECK(type IN (
        'TASK', 'RULE_VALIDATION', 'RULE_FIELD_UPDATE', 'RULE_ASSIGNMENT',
        'RULE_ESCALATION', 'RULE_STATE_CHECK',
        'AI_CLASSIFY', 'AI_GENERATE', 'AI_SUMMARIZE', 'DATA_QUALITY'
    )),
    status TEXT NOT NULL DEFAULT 'Pending' CHECK(status IN (
        'Pending', 'In Progress', 'Completed', 'Failed', 'Skipped'
    )),
    priority TEXT DEFAULT 'Medium' CHECK(priority IN ('High', 'Medium', 'Low')),

    rule_entry_id INTEGER,
    action_json TEXT,

    result_summary TEXT,
    result_json TEXT,

    assigned_to_id INTEGER,
    completed_by TEXT,
    completed_at DATETIME,

    attempts INTEGER DEFAULT 0,
    last_error TEXT,
    due_date DATETIME,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by_id INTEGER,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (parent_object_id) REFERENCES sys_objects(id),
    FOREIGN KEY (parent_record_id) REFERENCES data_records(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_field_id) REFERENCES sys_fields(id),
    FOREIGN KEY (rule_entry_id) REFERENCES sys_rule_entry(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to_id) REFERENCES sys_users(id),
    FOREIGN KEY (created_by_id) REFERENCES sys_users(id)
);

CREATE INDEX idx_op_activities_queue ON op_activities(tenant_id, status, priority, created_at)
    WHERE status = 'Pending';
CREATE INDEX idx_op_activities_parent ON op_activities(parent_object_id, parent_record_id, created_at DESC);
CREATE INDEX idx_op_activities_rule ON op_activities(rule_entry_id) WHERE rule_entry_id IS NOT NULL;

CREATE TABLE op_notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tenant_id INTEGER NOT NULL,

    -- Polymorphic parent: object + record + optional field
    parent_object_id INTEGER NOT NULL,
    parent_record_id INTEGER NOT NULL,
    parent_field_id INTEGER,

    activity_id INTEGER,

    body TEXT,
    type TEXT NOT NULL DEFAULT 'COMMENT' CHECK(type IN (
        'COMMENT', 'LLM_REASONING', 'SYSTEM', 'RULE_LOG', 'ATTACHMENT'
    )),

    -- File fields (only for type = ATTACHMENT)
    file_name TEXT,
    file_type TEXT,
    file_size INTEGER,
    content BLOB,

    author TEXT NOT NULL,
    created_by_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id) REFERENCES sys_tenants(id),
    FOREIGN KEY (parent_object_id) REFERENCES sys_objects(id),
    FOREIGN KEY (parent_record_id) REFERENCES data_records(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_field_id) REFERENCES sys_fields(id),
    FOREIGN KEY (activity_id) REFERENCES op_activities(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_id) REFERENCES sys_users(id)
);

CREATE INDEX idx_op_notes_parent ON op_notes(parent_object_id, parent_record_id, created_at DESC);
CREATE INDEX idx_op_notes_activity ON op_notes(activity_id) WHERE activity_id IS NOT NULL;
CREATE INDEX idx_op_notes_attachments ON op_notes(parent_object_id, parent_record_id)
    WHERE type = 'ATTACHMENT';

-- ── Token/TEAV ───────────────────────────────────────────────────────────

CREATE TABLE token (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nm TEXT UNIQUE NOT NULL
);

CREATE TABLE teav (
    t integer not null references token(id),
    e integer not null references token(id),
    a integer not null references token(id),
    v integer not null references token(id),
    primary key(t, e, a)
);

-- Indexes
CREATE INDEX idx_records_tenant ON data_records(tenant_id, object_id);
CREATE INDEX teav_tae on teav(t, a, e);
CREATE INDEX teav_tav on teav(t, a, v);
CREATE INDEX teav_tva on teav(t, v, a);
CREATE INDEX teav_tev on teav(t, e, v);
CREATE INDEX teav_tve on teav(t, v, e);
-- EAV Schema: Views

CREATE VIEW v_session_ctx AS
SELECT
    s.session_token,
    s.tenant_id,
    s.user_id,
    u.profile_id,
    u.role_id,
    s.expires_at
FROM sys_sessions s
JOIN sys_users u ON u.id = s.user_id;

CREATE VIEW v_records_all AS
SELECT
    r.id,
    t.name AS tenant_name,
    o.api_name AS object_name,
    rt.api_name AS record_type,
    u.username AS owner,
    (SELECT json_group_object(f.api_name,
        COALESCE(vt.value, vn.value, vl.target_record_id))
     FROM sys_fields f
     LEFT JOIN val_text vt ON f.id = vt.field_id AND vt.record_id = r.id
     LEFT JOIN val_numeric vn ON f.id = vn.field_id AND vn.record_id = r.id
     LEFT JOIN val_lookup vl ON f.id = vl.field_id AND vl.record_id = r.id
     WHERE f.object_id = r.object_id) AS fields_json
FROM data_records r
JOIN sys_tenants t ON r.tenant_id = t.id
JOIN sys_objects o ON r.object_id = o.id
JOIN sys_record_types rt ON r.record_type_id = rt.id
JOIN sys_users u ON r.owner_id = u.id
WHERE r.is_deleted = 0;

CREATE VIEW v_records_secure AS
WITH RECURSIVE subordinates(role_id, viewer_user_id) AS (
    SELECT u.role_id, s.user_id
    FROM sys_users u
    JOIN sys_sessions s ON u.id = s.user_id

    UNION ALL

    SELECT r.id, s.viewer_user_id
    FROM sys_roles r
    JOIN subordinates s ON r.parent_role_id = s.role_id
)
SELECT
    s.session_token,
    r.id AS record_id,
    o.api_name AS object_api_name,
    rt.api_name AS record_type_api_name,
    owner.username AS owner_username,
    r.created_at,
    (SELECT json_group_object(f.api_name,
        COALESCE(vt.value, CAST(vn.value AS TEXT), CAST(vl.target_record_id AS TEXT)))
     FROM sys_fields f
     LEFT JOIN val_text vt ON f.id = vt.field_id AND vt.record_id = r.id
     LEFT JOIN val_numeric vn ON f.id = vn.field_id AND vn.record_id = r.id
     LEFT JOIN val_lookup vl ON f.id = vl.field_id AND vl.record_id = r.id
     WHERE f.object_id = r.object_id) AS data_json
FROM sys_sessions s
JOIN data_records r ON s.tenant_id = r.tenant_id
JOIN sys_objects o ON r.object_id = o.id
JOIN sys_record_types rt ON r.record_type_id = rt.id
JOIN sys_users owner ON r.owner_id = owner.id
JOIN sys_users viewer ON s.user_id = viewer.id
LEFT JOIN sys_object_perms p ON viewer.profile_id = p.profile_id AND r.object_id = p.object_id
WHERE s.expires_at > datetime('now')
  AND r.is_deleted = 0
  AND (
      r.owner_id = s.user_id
      OR COALESCE(p.view_all, 0) = 1
      OR owner.role_id IN (SELECT role_id FROM subordinates WHERE viewer_user_id = s.user_id)
  );

CREATE VIEW v_ui_nav_menu AS
SELECT
    sc.session_token,
    a.api_name AS app_api_name,
    a.label AS app_label,
    a.nav_type AS app_nav_type,
    ap.is_default AS is_default_app,
    json_group_array(
        CASE WHEN t.id IS NULL THEN NULL
        ELSE json_object(
            'tab_label', t.label,
            'tab_api_name', t.api_name,
            'object_api_name', o.api_name,
            'icon', t.icon_name,
            'order', at.sequence
        ) END
    ) AS tabs_json
FROM v_session_ctx sc
JOIN sys_app_perms ap ON sc.profile_id = ap.profile_id
JOIN sys_apps a ON ap.app_id = a.id
LEFT JOIN sys_app_tabs at ON a.id = at.app_id
LEFT JOIN sys_tabs t ON at.tab_id = t.id
LEFT JOIN sys_objects o ON t.object_id = o.id
WHERE ap.is_visible = 1
GROUP BY sc.session_token, a.id;

CREATE VIEW v2_session_ctx AS
SELECT
    s.session_token,
    s.tenant_id,
    s.user_id,
    u.username,
    u.profile_id,
    p.name AS profile_name,
    u.role_id,
    r.name AS role_name,
    s.expires_at
FROM sys_sessions s
JOIN sys_users u ON u.id = s.user_id
LEFT JOIN sys_profiles p ON p.id = u.profile_id
LEFT JOIN sys_roles r ON r.id = u.role_id;

CREATE VIEW v2_ui_nav_menu AS
SELECT * FROM v_ui_nav_menu;

CREATE VIEW v2_record_kv AS
SELECT vt.record_id, f.api_name AS field_api_name, vt.value AS value
FROM val_text vt
JOIN sys_fields f ON f.id = vt.field_id
UNION ALL
SELECT vn.record_id, f.api_name, CAST(vn.value AS TEXT)
FROM val_numeric vn
JOIN sys_fields f ON f.id = vn.field_id
UNION ALL
SELECT vl.record_id, f.api_name, CAST(vl.target_record_id AS TEXT)
FROM val_lookup vl
JOIN sys_fields f ON f.id = vl.field_id;

CREATE VIEW v2_records_all AS
SELECT
    r.id AS record_id,
    o.api_name AS object_api_name,
    rt.api_name AS record_type_api_name,
    r.tenant_id,
    r.owner_id,
    r.created_at,
    r.last_modified_at,
    r.is_deleted,
    COALESCE(
        (SELECT json_group_object(k.field_api_name, k.value)
         FROM v2_record_kv k
         WHERE k.record_id = r.id),
        json('{}')
    ) AS fields_json
FROM data_records r
JOIN sys_objects o ON o.id = r.object_id AND o.tenant_id = r.tenant_id
LEFT JOIN sys_record_types rt ON rt.id = r.record_type_id AND rt.tenant_id = r.tenant_id
WHERE COALESCE(r.is_deleted, 0) = 0;

CREATE VIEW v2_ui_records_list AS
SELECT
    session_token,
    record_id,
    object_api_name,
    record_type_api_name,
    created_at,
    data_json
FROM v_records_secure;

CREATE VIEW v2_ui_record_detail AS
SELECT
    session_token,
    record_id,
    object_api_name,
    record_type_api_name,
    created_at,
    data_json
FROM v_records_secure;

CREATE VIEW v2_ui_object_summary AS
WITH ctx AS (
    SELECT s.session_token, s.tenant_id FROM sys_sessions s
)
SELECT
    c.session_token,
    o.tenant_id,
    o.api_name AS object_api_name,
    o.label AS object_label
FROM ctx c
JOIN sys_objects o ON o.tenant_id = c.tenant_id;

CREATE VIEW v2_ui_object_fields AS
WITH ctx AS (
    SELECT s.session_token, s.tenant_id FROM sys_sessions s
)
SELECT
    c.session_token,
    o.api_name AS object_api_name,
    f.api_name AS field_api_name,
    f.label AS field_label,
    f.data_type
FROM ctx c
JOIN sys_objects o ON o.tenant_id = c.tenant_id
JOIN sys_fields f ON f.tenant_id = o.tenant_id AND f.object_id = o.id;

CREATE VIEW v2_ui_layout_resolve AS
WITH ctx AS (
    SELECT sc.session_token, sc.tenant_id, sc.profile_id
    FROM v_session_ctx sc
)
SELECT
    ctx.session_token,
    o.api_name AS object_api_name,
    rt.api_name AS record_type_api_name,
    l.layout_type,
    l.id AS layout_id,
    l.name AS layout_name
FROM ctx
JOIN sys_objects o ON o.tenant_id = ctx.tenant_id
JOIN sys_record_types rt ON rt.tenant_id = o.tenant_id AND rt.object_id = o.id
JOIN sys_layout_assignments la ON la.profile_id = ctx.profile_id AND la.record_type_id = rt.id
JOIN sys_layouts l ON l.id = la.layout_id;

CREATE VIEW v2_ui_layout_fields_flat AS
SELECT
    lf.layout_id,
    lf.sequence,
    f.api_name AS field_api_name,
    f.label AS field_label,
    f.data_type,
    COALESCE(lf.is_required, 0) AS is_required,
    COALESCE(lf.is_read_only, 0) AS is_read_only
FROM sys_layout_fields lf
JOIN sys_fields f ON f.id = lf.field_id;

CREATE VIEW v_login AS
SELECT '' AS username, '' AS password, '' AS session_token;

CREATE VIEW v_logout AS
SELECT '' AS session_token;

CREATE VIEW v_signup_tenant AS
SELECT
    '' AS tenant_name,
    '' AS org_id,
    '' AS admin_username,
    '' AS admin_full_name;

CREATE VIEW v_insert_record_secure AS
SELECT
    '' AS session_token,
    '' AS object_api_name,
    '' AS record_type_api_name,
    '{}' AS json_data;

CREATE VIEW v_update_record_text_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, '' AS new_value;

CREATE VIEW v_update_record_numeric_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, 0.0 AS new_value;

CREATE VIEW v_update_record_picklist_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, '' AS selected_value;

CREATE VIEW v_update_record_lookup_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, 0 AS target_record_id;

CREATE VIEW v_update_record_date_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, '' AS new_value;

CREATE VIEW v_update_record_boolean_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, 0 AS new_value;

CREATE VIEW v_update_record_datetime_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, '' AS new_value;

CREATE VIEW v_manage_schema_secure AS
SELECT
    '' AS session_token,
    '' AS object_api_name,
    '' AS object_label,
    '' AS field_api_name,
    '' AS field_label,
    '' AS data_type,
    '' AS target_object_api_name;

CREATE VIEW v_update_object_label_secure AS
SELECT '' AS session_token, '' AS object_api_name, '' AS new_label;

CREATE VIEW v_delete_object_secure AS
SELECT '' AS session_token, '' AS object_api_name, 'BLOCK' AS delete_rule;

CREATE VIEW v_update_field_label_secure AS
SELECT '' AS session_token, 0 AS field_id, '' AS new_label;

CREATE VIEW v_update_field_target_secure AS
SELECT '' AS session_token, 0 AS field_id, '' AS target_object_api_name;

CREATE VIEW v_delete_field_secure AS
SELECT '' AS session_token, 0 AS field_id, 'BLOCK' AS delete_rule;

CREATE VIEW v_manage_picklist_value_secure AS
SELECT '' AS session_token, 0 AS field_id, '' AS value, '' AS label, 0 AS display_order;

CREATE VIEW v_delete_picklist_value_secure AS
SELECT '' AS session_token, 0 AS field_id, '' AS value;

CREATE VIEW v_manage_object_perms AS
SELECT
    '' AS profile_name,
    '' AS object_api_name,
    0 AS can_read,
    0 AS can_create,
    0 AS can_edit,
    0 AS can_delete,
    0 AS view_all,
    0 AS modify_all;

CREATE VIEW v_manage_field_perms AS
SELECT
    '' AS profile_name,
    '' AS object_api_name,
    '' AS field_api_name,
    0 AS can_read,
    0 AS can_edit;

CREATE VIEW v_manage_ui_layouts AS
SELECT
    '' AS session_token,
    '' AS object_api_name,
    '' AS layout_type,
    '' AS layout_name,
    '' AS field_api_name,
    0  AS sequence,
    0  AS is_read_only;

CREATE VIEW v_manage_layout_assignment AS
SELECT
    '' AS session_token,
    '' AS profile_name,
    '' AS record_type_api_name,
    '' AS layout_name;

CREATE VIEW v_create_layout_secure AS
SELECT '' AS session_token, '' AS object_api_name, '' AS layout_type, '' AS layout_name;

CREATE VIEW v_remove_layout_field_secure AS
SELECT '' AS session_token, '' AS layout_name, '' AS object_api_name, '' AS field_api_name;

CREATE VIEW v_delete_layout_secure AS
SELECT '' AS session_token, '' AS layout_name;

CREATE VIEW v_manage_index_secure AS
SELECT '' AS session_token, '' AS object_api_name, '' AS api_name, '' AS label, 1 AS is_unique;

CREATE VIEW v_add_index_field_secure AS
SELECT '' AS session_token, '' AS object_api_name, '' AS index_api_name, '' AS field_api_name, 1 AS sequence;

CREATE VIEW v_remove_index_field_secure AS
SELECT '' AS session_token, '' AS object_api_name, '' AS index_api_name, '' AS field_api_name;

CREATE VIEW v_delete_index_secure AS
SELECT '' AS session_token, '' AS object_api_name, '' AS api_name;

CREATE VIEW v_manage_app_assignment AS
SELECT
    '' AS session_token,
    '' AS profile_name,
    '' AS app_api_name,
    1  AS is_visible,
    0  AS is_default;

CREATE VIEW v_manage_app_secure AS
SELECT '' AS session_token, '' AS api_name, '' AS label, '' AS nav_type;

CREATE VIEW v_delete_app_secure AS
SELECT '' AS session_token, '' AS api_name;

CREATE VIEW v_manage_tab_secure AS
SELECT '' AS session_token, '' AS api_name, '' AS label, '' AS object_api_name, '' AS icon_name;

CREATE VIEW v_delete_tab_secure AS
SELECT '' AS session_token, '' AS api_name;

CREATE VIEW v_add_app_tab_secure AS
SELECT '' AS session_token, '' AS app_api_name, '' AS tab_api_name, 0 AS sequence;

CREATE VIEW v_remove_app_tab_secure AS
SELECT '' AS session_token, '' AS app_api_name, '' AS tab_api_name;

CREATE VIEW v_manage_role_secure AS
SELECT '' AS session_token, '' AS name, '' AS parent_role_name;

CREATE VIEW v_delete_role_secure AS
SELECT '' AS session_token, '' AS name;

CREATE VIEW v_manage_profile_secure AS
SELECT '' AS session_token, '' AS name, '' AS description;

CREATE VIEW v_delete_profile_secure AS
SELECT '' AS session_token, '' AS name;

CREATE VIEW v_manage_user_secure AS
SELECT '' AS session_token, '' AS username, '' AS full_name,
       '' AS password, '' AS profile_name, '' AS role_name, 1 AS is_active;

CREATE VIEW v_delete_user_secure AS
SELECT '' AS session_token, '' AS username;

CREATE VIEW v_delete_record_secure AS
SELECT '' AS session_token, 0 AS record_id;

CREATE VIEW v2_login AS
SELECT '' AS username, '' AS password;

CREATE VIEW v2_logout AS
SELECT '' AS session_token;

CREATE VIEW v2_insert_record_secure AS
SELECT '' AS session_token, '' AS object_api_name, '' AS record_type_api_name, '{}' AS json_data;

CREATE VIEW v2_update_record_text_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, '' AS value_text;

CREATE VIEW v2_update_record_numeric_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, NULL AS value_numeric;

CREATE VIEW v2_update_record_picklist_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, '' AS value_picklist;

CREATE VIEW v2_update_record_lookup_secure AS
SELECT '' AS session_token, 0 AS record_id, '' AS field_api_name, NULL AS value_record_id;

CREATE VIEW v2_manage_layout_upsert AS
SELECT '' AS session_token, '' AS object_api_name, '' AS layout_type, '' AS layout_name;

CREATE VIEW v2_manage_layout_assignment_upsert AS
SELECT
    '' AS session_token,
    '' AS object_api_name,
    '' AS record_type_api_name,
    '' AS layout_type,
    '' AS layout_name;

CREATE VIEW eav as 
select  t.nm as t,
        e.nm as e,
        a.nm as a,
        v.nm as v
from    teav
join    token t on t.id = teav.t
join    token e on e.id = teav.e
join    token a on a.id = teav.a
join    token v on v.id = teav.v;

-- EAV Schema: Triggers

CREATE TRIGGER tr_handle_login
INSTEAD OF INSERT ON v_login
BEGIN
    SELECT RAISE(ABORT, 'Invalid Username or Password')
    WHERE NOT EXISTS (SELECT 1 FROM sys_users WHERE username = NEW.username AND is_active = 1);

    SELECT RAISE(ABORT, 'Invalid Username or Password')
    WHERE EXISTS (
        SELECT 1 FROM sys_users
        WHERE username = NEW.username AND is_active = 1
          AND password_hash IS NOT NULL
          AND password_hash != NEW.password
    );

    INSERT INTO sys_sessions (user_id, tenant_id, session_token, expires_at)
    VALUES (
        (SELECT id FROM sys_users WHERE username = NEW.username),
        (SELECT tenant_id FROM sys_users WHERE username = NEW.username),
        lower(hex(randomblob(16))),
        datetime('now', '+8 hours')
    );
END;

CREATE TRIGGER tr_handle_logout
INSTEAD OF INSERT ON v_logout
BEGIN
    UPDATE sys_sessions
    SET expires_at = datetime('now', '-1 minute')
    WHERE session_token = NEW.session_token;
END;

CREATE TRIGGER tr_signup_tenant
INSTEAD OF INSERT ON v_signup_tenant
BEGIN
    INSERT INTO sys_tenants (name, org_id)
    VALUES (NEW.tenant_name, NEW.org_id);

    INSERT INTO sys_profiles (tenant_id, name)
    VALUES ((SELECT id FROM sys_tenants WHERE org_id = NEW.org_id), 'System Administrator');

    INSERT INTO sys_roles (tenant_id, name)
    VALUES ((SELECT id FROM sys_tenants WHERE org_id = NEW.org_id), 'CEO');

    INSERT INTO sys_users (tenant_id, profile_id, role_id, username, full_name)
    VALUES (
        (SELECT id FROM sys_tenants WHERE org_id = NEW.org_id),
        (SELECT id FROM sys_profiles WHERE tenant_id = (SELECT id FROM sys_tenants WHERE org_id = NEW.org_id) LIMIT 1),
        (SELECT id FROM sys_roles WHERE tenant_id = (SELECT id FROM sys_tenants WHERE org_id = NEW.org_id) LIMIT 1),
        NEW.admin_username,
        NEW.admin_full_name
    );
END;

CREATE TRIGGER tr_create_schema_secure
INSTEAD OF INSERT ON v_manage_schema_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    INSERT OR IGNORE INTO sys_objects (tenant_id, api_name, label)
    VALUES (
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        NEW.object_api_name,
        COALESCE(NULLIF(NEW.object_label, ''), NEW.object_api_name)
    );

    INSERT OR IGNORE INTO sys_record_types (object_id, tenant_id, api_name, label)
    VALUES (
        (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
         AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)),
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        'Master', 'Master'
    );

    -- Skip field creation when field_api_name is empty (object-only provisioning)
    INSERT INTO sys_fields (object_id, tenant_id, api_name, label, data_type, target_object_id)
    SELECT
        (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
         AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)),
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        NEW.field_api_name,
        COALESCE(NULLIF(NEW.field_label, ''), NEW.field_api_name),
        NEW.data_type,
        NULLIF((SELECT id FROM sys_objects WHERE api_name = NEW.target_object_api_name
                AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)), 0)
    WHERE NEW.field_api_name != '';
END
;

CREATE TRIGGER tr_insert_record_secure
INSTEAD OF INSERT ON v_insert_record_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unknown object_api_name for tenant')
    WHERE (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
           AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)) IS NULL;

    SELECT RAISE(ABORT, 'No object create permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN sys_objects o ON o.tenant_id = sc.tenant_id AND o.api_name = NEW.object_api_name
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = o.id
        WHERE sc.session_token = NEW.session_token AND (op.can_create = 1 OR op.modify_all = 1)
    );

    SELECT RAISE(ABORT, 'json_data contains unknown field(s)')
    WHERE EXISTS (
        SELECT 1 FROM json_each(NEW.json_data) je
        WHERE NOT EXISTS (
            SELECT 1 FROM sys_fields f
            WHERE f.tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
            AND f.object_id = (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name)
            AND f.api_name = je.key
        )
    );

    -- Unique index enforcement: for each active unique index on this object,
    -- reject if any existing record matches ALL indexed field values from json_data.
    -- Uses double negation: no index field exists where the value does NOT match.
    SELECT RAISE(ABORT, 'Duplicate value violates unique index')
    WHERE EXISTS (
        SELECT 1
        FROM sys_indexes si
        JOIN sys_objects o ON o.id = si.object_id
        JOIN data_records r ON r.object_id = o.id AND r.tenant_id = o.tenant_id AND r.is_deleted = 0
        WHERE o.api_name = NEW.object_api_name
        AND o.tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
        AND si.is_unique = 1 AND si.is_active = 1
        AND NOT EXISTS (
            SELECT 1 FROM sys_index_fields sif
            JOIN sys_fields f ON f.id = sif.field_id
            WHERE sif.index_id = si.id
            AND NOT EXISTS (
                SELECT 1 FROM json_each(NEW.json_data) je
                WHERE je.key = f.api_name
                AND (
                    EXISTS (SELECT 1 FROM val_text vt WHERE vt.record_id = r.id AND vt.field_id = f.id AND vt.value = je.value)
                    OR EXISTS (SELECT 1 FROM val_numeric vn WHERE vn.record_id = r.id AND vn.field_id = f.id AND CAST(vn.value AS TEXT) = je.value)
                )
            )
        )
    );

    INSERT INTO data_records (tenant_id, object_id, record_type_id, owner_id, created_by_id, last_modified_by_id)
    VALUES (
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
         AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)),
        (SELECT id FROM sys_record_types WHERE api_name = COALESCE(NULLIF(NEW.record_type_api_name, ''), 'Master')
         AND object_id = (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name)),
        (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token),
        (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token),
        (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    INSERT INTO v_update_record_text_secure (session_token, record_id, field_api_name, new_value)
    SELECT NEW.session_token, last_insert_rowid(), je.key, je.value
    FROM json_each(NEW.json_data) AS je
    WHERE EXISTS (SELECT 1 FROM sys_fields f WHERE f.api_name = je.key AND f.data_type = 'TEXT');

    INSERT INTO v_update_record_numeric_secure (session_token, record_id, field_api_name, new_value)
    SELECT NEW.session_token, last_insert_rowid(), je.key, je.value
    FROM json_each(NEW.json_data) AS je
    WHERE EXISTS (SELECT 1 FROM sys_fields f WHERE f.api_name = je.key AND f.data_type = 'NUMERIC');

    INSERT INTO v_update_record_picklist_secure (session_token, record_id, field_api_name, selected_value)
    SELECT NEW.session_token, last_insert_rowid(), je.key, je.value
    FROM json_each(NEW.json_data) AS je
    WHERE EXISTS (SELECT 1 FROM sys_fields f WHERE f.api_name = je.key AND f.data_type = 'PICKLIST');

    INSERT INTO v_update_record_lookup_secure (session_token, record_id, field_api_name, target_record_id)
    SELECT NEW.session_token, last_insert_rowid(), je.key, CAST(je.value AS INTEGER)
    FROM json_each(NEW.json_data) AS je
    WHERE EXISTS (SELECT 1 FROM sys_fields f WHERE f.api_name = je.key AND f.data_type = 'LOOKUP');

    INSERT INTO v_update_record_date_secure (session_token, record_id, field_api_name, new_value)
    SELECT NEW.session_token, last_insert_rowid(), je.key, je.value
    FROM json_each(NEW.json_data) AS je
    WHERE EXISTS (SELECT 1 FROM sys_fields f WHERE f.api_name = je.key AND f.data_type = 'DATE');

    INSERT INTO v_update_record_boolean_secure (session_token, record_id, field_api_name, new_value)
    SELECT NEW.session_token, last_insert_rowid(), je.key, CAST(je.value AS INTEGER)
    FROM json_each(NEW.json_data) AS je
    WHERE EXISTS (SELECT 1 FROM sys_fields f WHERE f.api_name = je.key AND f.data_type = 'BOOLEAN');

    INSERT INTO v_update_record_datetime_secure (session_token, record_id, field_api_name, new_value)
    SELECT NEW.session_token, last_insert_rowid(), je.key, je.value
    FROM json_each(NEW.json_data) AS je
    WHERE EXISTS (SELECT 1 FROM sys_fields f WHERE f.api_name = je.key AND f.data_type = 'DATETIME');

    SELECT RAISE(ABORT, 'Missing required field(s)')
    WHERE EXISTS (
        SELECT 1
        FROM sys_record_type_fields rtf
        JOIN sys_fields f ON f.id = rtf.field_id
        JOIN data_records r ON r.id = last_insert_rowid()
        WHERE rtf.record_type_id = r.record_type_id
        AND rtf.is_required = 1
        AND (
            (f.data_type IN ('TEXT','PICKLIST','DATE','DATETIME') AND NOT EXISTS (
                SELECT 1 FROM val_text vt WHERE vt.record_id = r.id AND vt.field_id = f.id AND vt.value IS NOT NULL))
            OR
            (f.data_type IN ('NUMERIC','BOOLEAN') AND NOT EXISTS (
                SELECT 1 FROM val_numeric vn WHERE vn.record_id = r.id AND vn.field_id = f.id AND vn.value IS NOT NULL))
            OR
            (f.data_type = 'LOOKUP' AND NOT EXISTS (
                SELECT 1 FROM val_lookup vl WHERE vl.record_id = r.id AND vl.field_id = f.id))
        )
    );
END
;

CREATE TRIGGER tr_update_record_text_secure
INSTEAD OF INSERT ON v_update_record_text_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Cross-tenant record update not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
    <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    SELECT RAISE(ABORT, 'No object edit permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_edit = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    SELECT RAISE(ABORT, 'Field not editable (missing/type mismatch/field perms/read-only)')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_fields f ON f.object_id = r.object_id AND f.tenant_id = r.tenant_id
        JOIN sys_field_perms fp ON fp.profile_id = sc.profile_id AND fp.field_id = f.id
        LEFT JOIN sys_record_type_fields rtf ON rtf.record_type_id = r.record_type_id AND rtf.field_id = f.id
        WHERE sc.session_token = NEW.session_token
        AND f.api_name = NEW.field_api_name
        AND f.data_type = 'TEXT'
        AND fp.can_edit = 1
        AND COALESCE(rtf.is_read_only, 0) = 0
    );

    INSERT OR REPLACE INTO val_text (record_id, field_id, value)
    VALUES (
        NEW.record_id,
        (SELECT f.id FROM sys_fields f
         JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
         WHERE r.id = NEW.record_id AND f.api_name = NEW.field_api_name AND f.data_type = 'TEXT'),
        NEW.new_value
    );

    UPDATE data_records
    SET last_modified_at = CURRENT_TIMESTAMP,
        system_modstamp = CURRENT_TIMESTAMP,
        last_modified_by_id = (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    WHERE id = NEW.record_id;
END;

CREATE TRIGGER tr_update_record_numeric_secure
INSTEAD OF INSERT ON v_update_record_numeric_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Cross-tenant record update not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
    <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    SELECT RAISE(ABORT, 'No object edit permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_edit = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    SELECT RAISE(ABORT, 'Field not editable')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_fields f ON f.object_id = r.object_id AND f.tenant_id = r.tenant_id
        JOIN sys_field_perms fp ON fp.profile_id = sc.profile_id AND fp.field_id = f.id
        LEFT JOIN sys_record_type_fields rtf ON rtf.record_type_id = r.record_type_id AND rtf.field_id = f.id
        WHERE sc.session_token = NEW.session_token
        AND f.api_name = NEW.field_api_name
        AND f.data_type = 'NUMERIC'
        AND fp.can_edit = 1
        AND COALESCE(rtf.is_read_only, 0) = 0
    );

    INSERT OR REPLACE INTO val_numeric (record_id, field_id, value)
    VALUES (
        NEW.record_id,
        (SELECT f.id FROM sys_fields f
         JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
         WHERE r.id = NEW.record_id AND f.api_name = NEW.field_api_name AND f.data_type = 'NUMERIC'),
        NEW.new_value
    );

    UPDATE data_records
    SET last_modified_at = CURRENT_TIMESTAMP,
        system_modstamp = CURRENT_TIMESTAMP,
        last_modified_by_id = (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    WHERE id = NEW.record_id;
END;

CREATE TRIGGER tr_update_record_picklist_secure
INSTEAD OF INSERT ON v_update_record_picklist_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Cross-tenant record update not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
    <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    SELECT RAISE(ABORT, 'No object edit permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_edit = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    SELECT RAISE(ABORT, 'Field not editable')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_fields f ON f.object_id = r.object_id AND f.tenant_id = r.tenant_id
        JOIN sys_field_perms fp ON fp.profile_id = sc.profile_id AND fp.field_id = f.id
        LEFT JOIN sys_record_type_fields rtf ON rtf.record_type_id = r.record_type_id AND rtf.field_id = f.id
        WHERE sc.session_token = NEW.session_token
        AND f.api_name = NEW.field_api_name
        AND f.data_type = 'PICKLIST'
        AND fp.can_edit = 1
        AND COALESCE(rtf.is_read_only, 0) = 0
    );

    SELECT RAISE(ABORT, 'Invalid Picklist Value')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_field_picklist_values pv
        JOIN sys_fields f ON pv.field_id = f.id
        JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
        WHERE r.id = NEW.record_id
        AND f.api_name = NEW.field_api_name
        AND pv.value = NEW.selected_value
        AND pv.is_active = 1
    );

    INSERT OR REPLACE INTO val_text (record_id, field_id, value)
    VALUES (
        NEW.record_id,
        (SELECT f.id FROM sys_fields f
         JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
         WHERE r.id = NEW.record_id AND f.api_name = NEW.field_api_name AND f.data_type = 'PICKLIST'),
        NEW.selected_value
    );

    UPDATE data_records
    SET last_modified_at = CURRENT_TIMESTAMP,
        system_modstamp = CURRENT_TIMESTAMP,
        last_modified_by_id = (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    WHERE id = NEW.record_id;
END;

CREATE TRIGGER tr_update_record_lookup_secure
INSTEAD OF INSERT ON v_update_record_lookup_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Cross-tenant record update not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
    <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    SELECT RAISE(ABORT, 'No object edit permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_edit = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    SELECT RAISE(ABORT, 'Cross-tenant lookup is not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.target_record_id)
    <> (SELECT tenant_id FROM data_records WHERE id = NEW.record_id);

    INSERT OR REPLACE INTO val_lookup (record_id, field_id, target_record_id)
    VALUES (
        NEW.record_id,
        (SELECT f.id FROM sys_fields f
         JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
         WHERE r.id = NEW.record_id AND f.api_name = NEW.field_api_name AND f.data_type = 'LOOKUP'),
        NEW.target_record_id
    );

    UPDATE data_records
    SET last_modified_at = CURRENT_TIMESTAMP,
        system_modstamp = CURRENT_TIMESTAMP,
        last_modified_by_id = (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    WHERE id = NEW.record_id;
END;

CREATE TRIGGER tr_update_record_date_secure
INSTEAD OF INSERT ON v_update_record_date_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Cross-tenant record update not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
    <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    SELECT RAISE(ABORT, 'No object edit permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_edit = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    INSERT OR REPLACE INTO val_text (record_id, field_id, value)
    VALUES (
        NEW.record_id,
        (SELECT f.id FROM sys_fields f
         JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
         WHERE r.id = NEW.record_id AND f.api_name = NEW.field_api_name AND f.data_type = 'DATE'),
        NEW.new_value
    );

    UPDATE data_records
    SET last_modified_at = CURRENT_TIMESTAMP,
        system_modstamp = CURRENT_TIMESTAMP,
        last_modified_by_id = (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    WHERE id = NEW.record_id;
END;

CREATE TRIGGER tr_update_record_boolean_secure
INSTEAD OF INSERT ON v_update_record_boolean_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Cross-tenant record update not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
    <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    SELECT RAISE(ABORT, 'No object edit permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_edit = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    SELECT RAISE(ABORT, 'BOOLEAN value must be 0 or 1')
    WHERE CAST(NEW.new_value AS INTEGER) NOT IN (0, 1);

    INSERT OR REPLACE INTO val_numeric (record_id, field_id, value)
    VALUES (
        NEW.record_id,
        (SELECT f.id FROM sys_fields f
         JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
         WHERE r.id = NEW.record_id AND f.api_name = NEW.field_api_name AND f.data_type = 'BOOLEAN'),
        CAST(NEW.new_value AS INTEGER)
    );

    UPDATE data_records
    SET last_modified_at = CURRENT_TIMESTAMP,
        system_modstamp = CURRENT_TIMESTAMP,
        last_modified_by_id = (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    WHERE id = NEW.record_id;
END;

CREATE TRIGGER tr_update_record_datetime_secure
INSTEAD OF INSERT ON v_update_record_datetime_secure
BEGIN
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Cross-tenant record update not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
    <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    SELECT RAISE(ABORT, 'No object edit permission')
    WHERE NOT EXISTS (
        SELECT 1
        FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_edit = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    INSERT OR REPLACE INTO val_text (record_id, field_id, value)
    VALUES (
        NEW.record_id,
        (SELECT f.id FROM sys_fields f
         JOIN data_records r ON r.object_id = f.object_id AND r.tenant_id = f.tenant_id
         WHERE r.id = NEW.record_id AND f.api_name = NEW.field_api_name AND f.data_type = 'DATETIME'),
        NEW.new_value
    );

    UPDATE data_records
    SET last_modified_at = CURRENT_TIMESTAMP,
        system_modstamp = CURRENT_TIMESTAMP,
        last_modified_by_id = (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token)
    WHERE id = NEW.record_id;
END;

CREATE TRIGGER tr_manage_object_perms
INSTEAD OF INSERT ON v_manage_object_perms
BEGIN
    INSERT OR REPLACE INTO sys_object_perms (
        profile_id, object_id, can_read, can_create, can_edit, can_delete, view_all, modify_all
    )
    VALUES (
        (SELECT id FROM sys_profiles WHERE name = NEW.profile_name),
        (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name),
        NEW.can_read, NEW.can_create, NEW.can_edit, NEW.can_delete, NEW.view_all, NEW.modify_all
    );
END;

CREATE TRIGGER tr_manage_field_perms
INSTEAD OF INSERT ON v_manage_field_perms
BEGIN
    INSERT OR REPLACE INTO sys_field_perms (profile_id, field_id, can_read, can_edit)
    VALUES (
        (SELECT id FROM sys_profiles WHERE name = NEW.profile_name),
        (SELECT f.id FROM sys_fields f
         JOIN sys_objects o ON f.object_id = o.id
         WHERE o.api_name = NEW.object_api_name AND f.api_name = NEW.field_api_name),
        NEW.can_read, NEW.can_edit
    );
END;

CREATE TRIGGER tr_manage_ui_layouts
INSTEAD OF INSERT ON v_manage_ui_layouts
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    INSERT OR IGNORE INTO sys_layouts (tenant_id, object_id, layout_type, name)
    VALUES (
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name),
        NEW.layout_type,
        NEW.layout_name
    );

    INSERT OR REPLACE INTO sys_layout_fields (layout_id, field_id, sequence, is_read_only)
    VALUES (
        (SELECT id FROM sys_layouts WHERE name = NEW.layout_name),
        (SELECT id FROM sys_fields WHERE api_name = NEW.field_api_name
         AND object_id = (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name)),
        NEW.sequence,
        NEW.is_read_only
    );
END;

CREATE TRIGGER tr_manage_layout_assignment
INSTEAD OF INSERT ON v_manage_layout_assignment
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    INSERT OR REPLACE INTO sys_layout_assignments (tenant_id, profile_id, record_type_id, layout_id)
    VALUES (
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        (SELECT id FROM sys_profiles WHERE name = NEW.profile_name),
        (SELECT id FROM sys_record_types WHERE api_name = NEW.record_type_api_name),
        (SELECT id FROM sys_layouts WHERE name = NEW.layout_name)
    );
END;

CREATE TRIGGER tr_manage_app_assignment
INSTEAD OF INSERT ON v_manage_app_assignment
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    INSERT OR REPLACE INTO sys_app_perms (profile_id, app_id, is_visible, is_default)
    VALUES (
        (SELECT id FROM sys_profiles WHERE name = NEW.profile_name),
        (SELECT id FROM sys_apps WHERE api_name = NEW.app_api_name),
        NEW.is_visible,
        NEW.is_default
    );
END;

CREATE TRIGGER tr_manage_app_secure
INSTEAD OF INSERT ON v_manage_app_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'api_name is required') WHERE TRIM(NEW.api_name) = '';
    SELECT RAISE(ABORT, 'label is required')    WHERE TRIM(NEW.label)    = '';

    INSERT INTO sys_apps(tenant_id, api_name, label, nav_type)
    SELECT (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
           TRIM(NEW.api_name), TRIM(NEW.label),
           COALESCE(NULLIF(TRIM(NEW.nav_type), ''), 'Standard')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_apps
        WHERE api_name = TRIM(NEW.api_name)
          AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    UPDATE sys_apps SET
        label    = TRIM(NEW.label),
        nav_type = COALESCE(NULLIF(TRIM(NEW.nav_type), ''), 'Standard')
    WHERE api_name  = TRIM(NEW.api_name)
      AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_delete_app_secure
INSTEAD OF INSERT ON v_delete_app_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'App not found')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_apps
        WHERE api_name = NEW.api_name
          AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    DELETE FROM sys_app_perms
    WHERE app_id = (SELECT id FROM sys_apps WHERE api_name = NEW.api_name
                    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token));

    DELETE FROM sys_app_tabs
    WHERE app_id = (SELECT id FROM sys_apps WHERE api_name = NEW.api_name
                    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token));

    DELETE FROM sys_apps
    WHERE api_name  = NEW.api_name
      AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_manage_tab_secure
INSTEAD OF INSERT ON v_manage_tab_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'api_name is required') WHERE TRIM(NEW.api_name) = '';
    SELECT RAISE(ABORT, 'label is required')    WHERE TRIM(NEW.label)    = '';

    INSERT INTO sys_tabs(tenant_id, api_name, label, object_id, icon_name)
    SELECT (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
           TRIM(NEW.api_name), TRIM(NEW.label),
           (SELECT id FROM sys_objects WHERE api_name = TRIM(NEW.object_api_name)
            AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)),
           NULLIF(TRIM(NEW.icon_name), '')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_tabs
        WHERE api_name = TRIM(NEW.api_name)
          AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    UPDATE sys_tabs SET
        label     = TRIM(NEW.label),
        object_id = (SELECT id FROM sys_objects WHERE api_name = TRIM(NEW.object_api_name)
                     AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)),
        icon_name = NULLIF(TRIM(NEW.icon_name), '')
    WHERE api_name  = TRIM(NEW.api_name)
      AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_delete_tab_secure
INSTEAD OF INSERT ON v_delete_tab_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'Tab not found')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_tabs
        WHERE api_name = NEW.api_name
          AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    DELETE FROM sys_app_tabs
    WHERE tab_id = (SELECT id FROM sys_tabs WHERE api_name = NEW.api_name
                    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token));

    DELETE FROM sys_tabs
    WHERE api_name  = NEW.api_name
      AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_add_app_tab_secure
INSTEAD OF INSERT ON v_add_app_tab_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'App not found') WHERE NOT EXISTS (SELECT 1 FROM sys_apps WHERE api_name = NEW.app_api_name);
    SELECT RAISE(ABORT, 'Tab not found') WHERE NOT EXISTS (SELECT 1 FROM sys_tabs WHERE api_name = NEW.tab_api_name);

    INSERT OR REPLACE INTO sys_app_tabs(app_id, tab_id, sequence)
    VALUES (
        (SELECT id FROM sys_apps WHERE api_name = NEW.app_api_name),
        (SELECT id FROM sys_tabs WHERE api_name = NEW.tab_api_name),
        NEW.sequence
    );
END;

CREATE TRIGGER tr_remove_app_tab_secure
INSTEAD OF INSERT ON v_remove_app_tab_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    DELETE FROM sys_app_tabs
    WHERE app_id = (SELECT id FROM sys_apps WHERE api_name = NEW.app_api_name)
      AND tab_id = (SELECT id FROM sys_tabs  WHERE api_name = NEW.tab_api_name);
END;

CREATE TRIGGER tr_create_layout_secure
INSTEAD OF INSERT ON v_create_layout_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'layout_name is required') WHERE TRIM(NEW.layout_name) = '';
    SELECT RAISE(ABORT, 'Object not found')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_objects
        WHERE api_name = NEW.object_api_name
          AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );
    INSERT OR IGNORE INTO sys_layouts (tenant_id, object_id, layout_type, name)
    VALUES (
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name),
        UPPER(TRIM(NEW.layout_type)),
        TRIM(NEW.layout_name)
    );
END;

CREATE TRIGGER tr_remove_layout_field_secure
INSTEAD OF INSERT ON v_remove_layout_field_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    DELETE FROM sys_layout_fields
    WHERE layout_id = (SELECT id FROM sys_layouts WHERE name = NEW.layout_name)
      AND field_id  = (SELECT id FROM sys_fields
                       WHERE api_name = NEW.field_api_name
                         AND object_id = (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name));
END;

CREATE TRIGGER tr_delete_layout_secure
INSTEAD OF INSERT ON v_delete_layout_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'Layout not found')
    WHERE NOT EXISTS (SELECT 1 FROM sys_layouts WHERE name = NEW.layout_name);

    DELETE FROM sys_layout_assignments
    WHERE layout_id = (SELECT id FROM sys_layouts WHERE name = NEW.layout_name);

    DELETE FROM sys_layout_fields
    WHERE layout_id = (SELECT id FROM sys_layouts WHERE name = NEW.layout_name);

    DELETE FROM sys_layouts WHERE name = NEW.layout_name;
END;

CREATE TRIGGER tr_manage_index_secure
INSTEAD OF INSERT ON v_manage_index_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'api_name is required') WHERE TRIM(NEW.api_name) = '';
    SELECT RAISE(ABORT, 'Object not found')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_objects
        WHERE api_name  = NEW.object_api_name
          AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    INSERT INTO sys_indexes (tenant_id, object_id, api_name, label, is_unique)
    SELECT (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
           (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name),
           TRIM(NEW.api_name),
           COALESCE(NULLIF(TRIM(NEW.label), ''), TRIM(NEW.api_name)),
           NEW.is_unique
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_indexes
        WHERE api_name  = TRIM(NEW.api_name)
          AND object_id = (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name)
    );

    UPDATE sys_indexes SET
        label     = COALESCE(NULLIF(TRIM(NEW.label), ''), TRIM(NEW.api_name)),
        is_unique = NEW.is_unique
    WHERE api_name  = TRIM(NEW.api_name)
      AND object_id = (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name);
END;

CREATE TRIGGER tr_add_index_field_secure
INSTEAD OF INSERT ON v_add_index_field_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'Index not found')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_indexes si JOIN sys_objects o ON o.id = si.object_id
        WHERE si.api_name = NEW.index_api_name AND o.api_name = NEW.object_api_name
    );
    SELECT RAISE(ABORT, 'Field not found on this object')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_fields f JOIN sys_objects o ON o.id = f.object_id
        WHERE f.api_name = NEW.field_api_name AND o.api_name = NEW.object_api_name
    );

    INSERT OR REPLACE INTO sys_index_fields (index_id, field_id, sequence)
    VALUES (
        (SELECT si.id FROM sys_indexes si JOIN sys_objects o ON o.id = si.object_id
         WHERE si.api_name = NEW.index_api_name AND o.api_name = NEW.object_api_name),
        (SELECT f.id FROM sys_fields f JOIN sys_objects o ON o.id = f.object_id
         WHERE f.api_name = NEW.field_api_name AND o.api_name = NEW.object_api_name),
        NEW.sequence
    );
END;

CREATE TRIGGER tr_remove_index_field_secure
INSTEAD OF INSERT ON v_remove_index_field_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    DELETE FROM sys_index_fields
    WHERE index_id = (
        SELECT si.id FROM sys_indexes si JOIN sys_objects o ON o.id = si.object_id
        WHERE si.api_name = NEW.index_api_name AND o.api_name = NEW.object_api_name
    )
    AND field_id = (
        SELECT f.id FROM sys_fields f JOIN sys_objects o ON o.id = f.object_id
        WHERE f.api_name = NEW.field_api_name AND o.api_name = NEW.object_api_name
    );
END;

CREATE TRIGGER tr_delete_index_secure
INSTEAD OF INSERT ON v_delete_index_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Admin session required')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );
    SELECT RAISE(ABORT, 'Index not found')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_indexes si JOIN sys_objects o ON o.id = si.object_id
        WHERE si.api_name = NEW.api_name AND o.api_name = NEW.object_api_name
    );

    -- sys_index_fields cascade automatically via ON DELETE CASCADE
    DELETE FROM sys_indexes
    WHERE api_name  = NEW.api_name
      AND object_id = (SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name);
END
;

CREATE TRIGGER tr_v2_login_insert
INSTEAD OF INSERT ON v2_login
BEGIN
    INSERT INTO v_login(username, password) VALUES (NEW.username, NEW.password);
END;

CREATE TRIGGER tr_v2_logout_insert
INSTEAD OF INSERT ON v2_logout
BEGIN
    INSERT INTO v_logout(session_token) VALUES (NEW.session_token);
END;

CREATE TRIGGER tr_v2_insert_record_secure_insert
INSTEAD OF INSERT ON v2_insert_record_secure
BEGIN
    INSERT INTO v_insert_record_secure(session_token, object_api_name, record_type_api_name, json_data)
    VALUES (NEW.session_token, NEW.object_api_name, NEW.record_type_api_name, NEW.json_data);
END;

CREATE TRIGGER tr_v2_update_record_text_secure_insert
INSTEAD OF INSERT ON v2_update_record_text_secure
BEGIN
    INSERT INTO v_update_record_text_secure(session_token, record_id, field_api_name, new_value)
    VALUES (NEW.session_token, NEW.record_id, NEW.field_api_name, NEW.value_text);
END;

CREATE TRIGGER tr_v2_update_record_numeric_secure_insert
INSTEAD OF INSERT ON v2_update_record_numeric_secure
BEGIN
    INSERT INTO v_update_record_numeric_secure(session_token, record_id, field_api_name, new_value)
    VALUES (NEW.session_token, NEW.record_id, NEW.field_api_name, NEW.value_numeric);
END;

CREATE TRIGGER tr_v2_update_record_picklist_secure_insert
INSTEAD OF INSERT ON v2_update_record_picklist_secure
BEGIN
    INSERT INTO v_update_record_picklist_secure(session_token, record_id, field_api_name, selected_value)
    VALUES (NEW.session_token, NEW.record_id, NEW.field_api_name, NEW.value_picklist);
END;

CREATE TRIGGER tr_v2_update_record_lookup_secure_insert
INSTEAD OF INSERT ON v2_update_record_lookup_secure
BEGIN
    INSERT INTO v_update_record_lookup_secure(session_token, record_id, field_api_name, target_record_id)
    VALUES (NEW.session_token, NEW.record_id, NEW.field_api_name, NEW.value_record_id);
END;

CREATE TRIGGER tr_v2_manage_layout_upsert_insert
INSTEAD OF INSERT ON v2_manage_layout_upsert
BEGIN
    INSERT INTO v_manage_ui_layouts(session_token, object_api_name, layout_type, layout_name)
    VALUES (NEW.session_token, NEW.object_api_name, NEW.layout_type, NEW.layout_name);
END;

CREATE TRIGGER tr_v2_manage_layout_assignment_upsert
INSTEAD OF INSERT ON v2_manage_layout_assignment_upsert
BEGIN
    INSERT INTO v_manage_layout_assignment(session_token, profile_name, record_type_api_name, layout_name)
    VALUES (NEW.session_token, NEW.object_api_name, NEW.record_type_api_name, NEW.layout_name);
END;

CREATE TRIGGER tr_update_object_label_secure
INSTEAD OF INSERT ON v_update_object_label_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Object not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_objects
        WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    UPDATE sys_objects
    SET label = NEW.new_label
    WHERE api_name = NEW.object_api_name
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_delete_object_secure
INSTEAD OF INSERT ON v_delete_object_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Object not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_objects
        WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- BLOCK: raise if any data records exist for this object
    SELECT RAISE(ABORT, 'Object has existing data records. Use delete_rule=CASCADE to delete all records and schema.')
    WHERE NEW.delete_rule = 'BLOCK'
    AND EXISTS (
        SELECT 1 FROM data_records r
        JOIN sys_objects o ON o.id = r.object_id
        WHERE o.api_name = NEW.object_api_name
        AND o.tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- CASCADE only: remove incoming lookup references from other objects pointing to this object's records
    DELETE FROM val_lookup
    WHERE NEW.delete_rule = 'CASCADE'
    AND target_record_id IN (
        SELECT r.id FROM data_records r
        JOIN sys_objects o ON o.id = r.object_id
        WHERE o.api_name = NEW.object_api_name
        AND o.tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- CASCADE only: delete data records (cascades val_text, val_numeric, val_embedding, val_lookup via record_id FK)
    DELETE FROM data_records
    WHERE NEW.delete_rule = 'CASCADE'
    AND object_id = (
        SELECT id FROM sys_objects
        WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Schema cleanup (always runs — same whether BLOCK with no data, or CASCADE after data removed)

    -- Layout assignments + layout fields + layouts (no FK cascade from sys_layouts)
    DELETE FROM sys_layout_assignments
    WHERE layout_id IN (
        SELECT l.id FROM sys_layouts l
        WHERE l.object_id = (
            SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
            AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
        )
    );

    DELETE FROM sys_layout_fields
    WHERE layout_id IN (
        SELECT l.id FROM sys_layouts l
        WHERE l.object_id = (
            SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
            AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
        )
    );

    DELETE FROM sys_layouts
    WHERE object_id = (
        SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- App tabs + tabs (no FK cascade from sys_tabs)
    DELETE FROM sys_app_tabs
    WHERE tab_id IN (
        SELECT t.id FROM sys_tabs t
        WHERE t.object_id = (
            SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
            AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
        )
    );

    DELETE FROM sys_tabs
    WHERE object_id = (
        SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Indexes (cascades sys_index_fields via FK)
    DELETE FROM sys_indexes
    WHERE object_id = (
        SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Layout fields by field_id before deleting fields (no FK cascade from sys_fields → sys_layout_fields)
    DELETE FROM sys_layout_fields
    WHERE field_id IN (
        SELECT f.id FROM sys_fields f
        WHERE f.object_id = (
            SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
            AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
        )
    );

    -- Fields (cascades sys_field_perms, sys_field_picklist_values, sys_record_type_fields, sys_index_fields)
    DELETE FROM sys_fields
    WHERE object_id = (
        SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Record types (no FK cascade from sys_objects)
    DELETE FROM sys_record_types
    WHERE object_id = (
        SELECT id FROM sys_objects WHERE api_name = NEW.object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Finally delete the object itself (cascades sys_object_perms)
    DELETE FROM sys_objects
    WHERE api_name = NEW.object_api_name
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END
;

CREATE TRIGGER tr_update_field_label_secure
INSTEAD OF INSERT ON v_update_field_label_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Field not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_fields
        WHERE id = NEW.field_id
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    UPDATE sys_fields
    SET label = NEW.new_label
    WHERE id = NEW.field_id
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_update_field_target_secure
INSTEAD OF INSERT ON v_update_field_target_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Field not found or not a LOOKUP field.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_fields
        WHERE id = NEW.field_id AND data_type = 'LOOKUP'
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    SELECT RAISE(ABORT, 'Target object not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_objects
        WHERE api_name = NEW.target_object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    UPDATE sys_fields
    SET target_object_id = (
        SELECT id FROM sys_objects
        WHERE api_name = NEW.target_object_api_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    )
    WHERE id = NEW.field_id
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_delete_field_secure
INSTEAD OF INSERT ON v_delete_field_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Field not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_fields
        WHERE id = NEW.field_id
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- BLOCK: raise with value count if any data exists for this field
    SELECT RAISE(ABORT, 'Field has existing values across records. Use delete_rule=CASCADE to remove all field values.')
    WHERE NEW.delete_rule = 'BLOCK'
    AND EXISTS (
        SELECT 1 FROM val_text    WHERE field_id = NEW.field_id UNION ALL
        SELECT 1 FROM val_numeric WHERE field_id = NEW.field_id UNION ALL
        SELECT 1 FROM val_lookup  WHERE field_id = NEW.field_id
        LIMIT 1
    );

    -- CASCADE: remove all values for this field across all records
    DELETE FROM val_text    WHERE field_id = NEW.field_id AND NEW.delete_rule = 'CASCADE';
    DELETE FROM val_numeric WHERE field_id = NEW.field_id AND NEW.delete_rule = 'CASCADE';
    DELETE FROM val_lookup  WHERE field_id = NEW.field_id AND NEW.delete_rule = 'CASCADE';

    -- Remove layout references (no FK cascade from sys_fields → sys_layout_fields)
    DELETE FROM sys_layout_fields WHERE field_id = NEW.field_id;

    -- Delete the field (cascades sys_field_perms, sys_field_picklist_values,
    --                   sys_record_type_fields, sys_index_fields)
    DELETE FROM sys_fields
    WHERE id = NEW.field_id
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END
;

CREATE TRIGGER tr_manage_picklist_value_secure
INSTEAD OF INSERT ON v_manage_picklist_value_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Field not found or not a PICKLIST field.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_fields
        WHERE id = NEW.field_id AND data_type = 'PICKLIST'
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    SELECT RAISE(ABORT, 'Value must not be empty.')
    WHERE NEW.value = '' OR NEW.value IS NULL;

    INSERT INTO sys_field_picklist_values(field_id, value, label, display_order, is_active)
    VALUES (
        NEW.field_id,
        NEW.value,
        COALESCE(NULLIF(NEW.label, ''), NEW.value),
        NEW.display_order,
        1
    )
    ON CONFLICT(field_id, value) DO UPDATE SET
        label         = excluded.label,
        display_order = excluded.display_order,
        is_active     = 1;
END;

CREATE TRIGGER tr_delete_picklist_value_secure
INSTEAD OF INSERT ON v_delete_picklist_value_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Picklist value not found.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_field_picklist_values pv
        JOIN sys_fields f ON f.id = pv.field_id
        WHERE pv.field_id = NEW.field_id AND pv.value = NEW.value
        AND f.tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    DELETE FROM sys_field_picklist_values
    WHERE field_id = NEW.field_id AND value = NEW.value;
END;

CREATE TRIGGER tr_manage_role_secure
INSTEAD OF INSERT ON v_manage_role_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Role name must not be empty.')
    WHERE NEW.name = '' OR NEW.name IS NULL;

    SELECT RAISE(ABORT, 'Parent role not found for this tenant.')
    WHERE NEW.parent_role_name != '' AND NEW.parent_role_name IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM sys_roles
        WHERE name = NEW.parent_role_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Insert if role does not yet exist
    INSERT INTO sys_roles(tenant_id, name, parent_role_id)
    SELECT
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        NEW.name,
        CASE WHEN NEW.parent_role_name != '' AND NEW.parent_role_name IS NOT NULL
             THEN (SELECT id FROM sys_roles
                   WHERE name = NEW.parent_role_name
                   AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token))
             ELSE NULL END
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_roles
        WHERE name = NEW.name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Update parent if role already existed
    UPDATE sys_roles
    SET parent_role_id =
        CASE WHEN NEW.parent_role_name != '' AND NEW.parent_role_name IS NOT NULL
             THEN (SELECT id FROM sys_roles
                   WHERE name = NEW.parent_role_name
                   AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token))
             ELSE NULL END
    WHERE name = NEW.name
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END
;

CREATE TRIGGER tr_delete_role_secure
INSTEAD OF INSERT ON v_delete_role_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Role not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_roles
        WHERE name = NEW.name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    SELECT RAISE(ABORT, 'Role has assigned users. Reassign users before deleting.')
    WHERE EXISTS (
        SELECT 1 FROM sys_users
        WHERE role_id = (SELECT id FROM sys_roles
                         WHERE name = NEW.name
                         AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token))
    );

    SELECT RAISE(ABORT, 'Role has child roles. Delete or reassign child roles first.')
    WHERE EXISTS (
        SELECT 1 FROM sys_roles
        WHERE parent_role_id = (SELECT id FROM sys_roles
                                WHERE name = NEW.name
                                AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token))
    );

    DELETE FROM sys_roles
    WHERE name = NEW.name
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END;

CREATE TRIGGER tr_manage_profile_secure
INSTEAD OF INSERT ON v_manage_profile_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Profile name must not be empty.')
    WHERE NEW.name = '' OR NEW.name IS NULL;

    -- Insert if profile does not yet exist
    INSERT INTO sys_profiles(tenant_id, name, description)
    SELECT
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        NEW.name,
        NULLIF(NEW.description, '')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_profiles
        WHERE name = NEW.name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Update description if profile already existed
    UPDATE sys_profiles
    SET description = NULLIF(NEW.description, '')
    WHERE name = NEW.name
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END
;

CREATE TRIGGER tr_delete_profile_secure
INSTEAD OF INSERT ON v_delete_profile_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Profile not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_profiles
        WHERE name = NEW.name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    SELECT RAISE(ABORT, 'Profile has assigned users. Reassign users before deleting.')
    WHERE EXISTS (
        SELECT 1 FROM sys_users
        WHERE profile_id = (SELECT id FROM sys_profiles
                            WHERE name = NEW.name
                            AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token))
    );

    -- Remove app perms and layout assignments (no FK cascade on these)
    DELETE FROM sys_app_perms
    WHERE profile_id = (SELECT id FROM sys_profiles
                        WHERE name = NEW.name
                        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token));

    DELETE FROM sys_layout_assignments
    WHERE profile_id = (SELECT id FROM sys_profiles
                        WHERE name = NEW.name
                        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token));

    -- Delete the profile (cascades sys_object_perms, sys_field_perms via ON DELETE CASCADE)
    DELETE FROM sys_profiles
    WHERE name = NEW.name
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END
;

CREATE TRIGGER tr_manage_user_secure
INSTEAD OF INSERT ON v_manage_user_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Username must not be empty.')
    WHERE NEW.username = '' OR NEW.username IS NULL;

    SELECT RAISE(ABORT, 'Profile not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_profiles
        WHERE name = NEW.profile_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    SELECT RAISE(ABORT, 'Role not found for this tenant.')
    WHERE NEW.role_name != '' AND NEW.role_name IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM sys_roles
        WHERE name = NEW.role_name
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    SELECT RAISE(ABORT, 'Username already taken by another tenant.')
    WHERE EXISTS (
        SELECT 1 FROM sys_users
        WHERE username = NEW.username
        AND tenant_id != (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    -- Insert if user does not yet exist
    INSERT INTO sys_users(tenant_id, profile_id, username, full_name, password_hash, is_active, role_id)
    SELECT
        (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token),
        (SELECT id FROM sys_profiles
         WHERE name = NEW.profile_name
         AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)),
        NEW.username,
        NULLIF(NEW.full_name, ''),
        NULLIF(NEW.password, ''),
        NEW.is_active,
        CASE WHEN NEW.role_name != '' AND NEW.role_name IS NOT NULL
             THEN (SELECT id FROM sys_roles
                   WHERE name = NEW.role_name
                   AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token))
             ELSE NULL END
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_users WHERE username = NEW.username
    );

    -- Update if user already existed (preserve password if not supplied)
    UPDATE sys_users
    SET profile_id    = (SELECT id FROM sys_profiles
                         WHERE name = NEW.profile_name
                         AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)),
        full_name     = COALESCE(NULLIF(NEW.full_name, ''), full_name),
        password_hash = CASE WHEN NEW.password != '' AND NEW.password IS NOT NULL
                             THEN NEW.password
                             ELSE password_hash END,
        is_active     = NEW.is_active,
        role_id       = CASE WHEN NEW.role_name != '' AND NEW.role_name IS NOT NULL
                             THEN (SELECT id FROM sys_roles
                                   WHERE name = NEW.role_name
                                   AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token))
                             ELSE NULL END
    WHERE username = NEW.username
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END
;

CREATE TRIGGER tr_delete_user_secure
INSTEAD OF INSERT ON v_delete_user_secure
BEGIN
    SELECT RAISE(ABORT, 'Unauthorized: Invalid or expired session.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    SELECT RAISE(ABORT, 'Unauthorized: Admin session required.')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id
        WHERE sc.session_token = NEW.session_token AND op.modify_all = 1
    );

    SELECT RAISE(ABORT, 'Cannot delete your own user account.')
    WHERE (SELECT user_id FROM sys_sessions WHERE session_token = NEW.session_token) =
          (SELECT id FROM sys_users WHERE username = NEW.username);

    SELECT RAISE(ABORT, 'User not found for this tenant.')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_users
        WHERE username = NEW.username
        AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token)
    );

    SELECT RAISE(ABORT, 'User owns active records. Reassign records before deleting.')
    WHERE EXISTS (
        SELECT 1 FROM data_records
        WHERE owner_id = (SELECT id FROM sys_users WHERE username = NEW.username)
        AND is_deleted = 0
    );

    -- Delete all sessions for this user (sys_sessions has no ON DELETE CASCADE)
    DELETE FROM sys_sessions
    WHERE user_id = (SELECT id FROM sys_users WHERE username = NEW.username);

    DELETE FROM sys_users
    WHERE username = NEW.username
    AND tenant_id = (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);
END
;

CREATE TRIGGER tr_delete_record_secure
INSTEAD OF INSERT ON v_delete_record_secure
BEGIN
    -- 1. Valid, unexpired session
    SELECT RAISE(ABORT, 'Invalid or Expired Session')
    WHERE NOT EXISTS (
        SELECT 1 FROM sys_sessions
        WHERE session_token = NEW.session_token AND expires_at > datetime('now')
    );

    -- 2. Cross-tenant isolation
    SELECT RAISE(ABORT, 'Cross-tenant delete not allowed')
    WHERE (SELECT tenant_id FROM data_records WHERE id = NEW.record_id)
       <> (SELECT tenant_id FROM sys_sessions WHERE session_token = NEW.session_token);

    -- 3. can_delete or modify_all permission (with record ownership check)
    SELECT RAISE(ABORT, 'No delete permission')
    WHERE NOT EXISTS (
        SELECT 1 FROM v_session_ctx sc
        JOIN data_records r ON r.id = NEW.record_id AND r.tenant_id = sc.tenant_id
        JOIN sys_object_perms op ON op.profile_id = sc.profile_id AND op.object_id = r.object_id
        WHERE sc.session_token = NEW.session_token
          AND (op.modify_all = 1
               OR (op.can_delete = 1 AND (
                   r.owner_id = sc.user_id
                   OR r.owner_id IN (
                       WITH RECURSIVE sub_roles AS (
                           SELECT id FROM sys_roles WHERE id = (SELECT role_id FROM sys_users WHERE id = sc.user_id)
                           UNION ALL
                           SELECT r2.id FROM sys_roles r2 JOIN sub_roles sr ON r2.parent_role_id = sr.id
                       )
                       SELECT u2.id FROM sys_users u2 WHERE u2.role_id IN (SELECT id FROM sub_roles)
                   )
               ))
          )
    );

    -- 4. Hard delete: clear incoming lookups (no CASCADE on target_record_id),
    --    then delete record (val_text/val_numeric/val_lookup/val_embedding CASCADE)
    DELETE FROM val_lookup WHERE target_record_id = NEW.record_id;
    DELETE FROM data_records WHERE id = NEW.record_id;
END
;

