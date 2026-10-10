-- Base44 sandbox: white-label the console's seeded data into Brazilian Portuguese.
--
-- The seed (ry_20260417.sql) is the upstream project's demo data: the company and department
-- names, the user nicknames, the role and job-title names, every dictionary label, the config
-- names, the demo jobs and notices are Chinese, and one top-level menu ("Site do RuoYi") is a
-- link to the vendor's website. This file replaces that data with neutral Brazilian Portuguese
-- and drops the vendor link, so the console reads entirely pt-BR with no upstream credits.
--
-- The MySQL entrypoint runs this during the initdb phase of a first boot (its name sorts after
-- the seed and after zz_base44_menu_urls_init.sh). Init scripts run only while the data volume
-- is empty; AGENTS.md explains how to apply this to an existing volume. Every statement is
-- keyed on the row's primary key, so re-running it on an already-translated database is
-- harmless.

-- Vendor website link (menu 4, http://ruoyi.vip) and the grants pointing at it.
DELETE FROM sys_role_menu WHERE menu_id = 4;
DELETE FROM sys_menu WHERE menu_id = 4;

-- Departments: neutral names, and the leader is no longer the vendor's name.
UPDATE sys_dept SET dept_name = 'Empresa',          leader = 'admin' WHERE dept_id = 100;
UPDATE sys_dept SET dept_name = 'Matriz',           leader = 'admin' WHERE dept_id = 101;
UPDATE sys_dept SET dept_name = 'Filial',           leader = 'admin' WHERE dept_id = 102;
UPDATE sys_dept SET dept_name = 'Desenvolvimento',  leader = 'admin' WHERE dept_id = 103;
UPDATE sys_dept SET dept_name = 'Marketing',        leader = 'admin' WHERE dept_id = 104;
UPDATE sys_dept SET dept_name = 'Qualidade',        leader = 'admin' WHERE dept_id = 105;
UPDATE sys_dept SET dept_name = 'Financeiro',       leader = 'admin' WHERE dept_id = 106;
UPDATE sys_dept SET dept_name = 'Infraestrutura',   leader = 'admin' WHERE dept_id = 107;
UPDATE sys_dept SET dept_name = 'Marketing',        leader = 'admin' WHERE dept_id = 108;
UPDATE sys_dept SET dept_name = 'Financeiro',       leader = 'admin' WHERE dept_id = 109;

-- Users: the nickname is shown in the navbar.
UPDATE sys_user SET nick_name = 'Administrador',     remark = 'Administrador'        WHERE user_id = 1;
UPDATE sys_user SET nick_name = 'Usuário de teste',  remark = 'Usuário de teste'     WHERE user_id = 2;

-- Profiles (roles).
UPDATE sys_role SET role_name = 'Administrador',  remark = 'Administrador'   WHERE role_id = 1;
UPDATE sys_role SET role_name = 'Perfil comum',   remark = 'Perfil comum'    WHERE role_id = 2;

-- Job titles (posts).
UPDATE sys_post SET post_name = 'Presidente' WHERE post_id = 1;
UPDATE sys_post SET post_name = 'Gerente de projetos' WHERE post_id = 2;
UPDATE sys_post SET post_name = 'Recursos humanos' WHERE post_id = 3;
UPDATE sys_post SET post_name = 'Colaborador' WHERE post_id = 4;

-- Dictionary types.
UPDATE sys_dict_type SET dict_name = 'Sexo do usuário',     remark = 'Lista de sexo do usuário'      WHERE dict_id = 1;
UPDATE sys_dict_type SET dict_name = 'Status do menu',      remark = 'Lista de status do menu'       WHERE dict_id = 2;
UPDATE sys_dict_type SET dict_name = 'Ativação do sistema', remark = 'Lista de ativação do sistema'  WHERE dict_id = 3;
UPDATE sys_dict_type SET dict_name = 'Status da tarefa',    remark = 'Lista de status da tarefa'     WHERE dict_id = 4;
UPDATE sys_dict_type SET dict_name = 'Grupo da tarefa',     remark = 'Lista de grupos de tarefa'     WHERE dict_id = 5;
UPDATE sys_dict_type SET dict_name = 'Sim ou não',          remark = 'Lista de sim ou não'           WHERE dict_id = 6;
UPDATE sys_dict_type SET dict_name = 'Tipo de aviso',       remark = 'Lista de tipos de aviso'       WHERE dict_id = 7;
UPDATE sys_dict_type SET dict_name = 'Status do aviso',     remark = 'Lista de status do aviso'      WHERE dict_id = 8;
UPDATE sys_dict_type SET dict_name = 'Tipo de operação',    remark = 'Lista de tipos de operação'    WHERE dict_id = 9;
UPDATE sys_dict_type SET dict_name = 'Status do sistema',   remark = 'Lista de status do sistema'    WHERE dict_id = 10;

-- Dictionary labels.
UPDATE sys_dict_data SET dict_label = 'Masculino',      remark = 'Sexo masculino'      WHERE dict_code = 1;
UPDATE sys_dict_data SET dict_label = 'Feminino',       remark = 'Sexo feminino'       WHERE dict_code = 2;
UPDATE sys_dict_data SET dict_label = 'Não informado',  remark = 'Sexo não informado'  WHERE dict_code = 3;
UPDATE sys_dict_data SET dict_label = 'Mostrar',        remark = 'Exibir o menu'       WHERE dict_code = 4;
UPDATE sys_dict_data SET dict_label = 'Ocultar',        remark = 'Ocultar o menu'      WHERE dict_code = 5;
UPDATE sys_dict_data SET dict_label = 'Ativo',          remark = 'Status ativo'        WHERE dict_code = 6;
UPDATE sys_dict_data SET dict_label = 'Inativo',        remark = 'Status inativo'      WHERE dict_code = 7;
UPDATE sys_dict_data SET dict_label = 'Ativo',          remark = 'Status ativo'        WHERE dict_code = 8;
UPDATE sys_dict_data SET dict_label = 'Pausado',        remark = 'Status pausado'      WHERE dict_code = 9;
UPDATE sys_dict_data SET dict_label = 'Padrão',         remark = 'Grupo padrão'        WHERE dict_code = 10;
UPDATE sys_dict_data SET dict_label = 'Sistema',        remark = 'Grupo do sistema'    WHERE dict_code = 11;
UPDATE sys_dict_data SET dict_label = 'Sim',            remark = 'Padrão do sistema: sim'  WHERE dict_code = 12;
UPDATE sys_dict_data SET dict_label = 'Não',            remark = 'Padrão do sistema: não'  WHERE dict_code = 13;
UPDATE sys_dict_data SET dict_label = 'Notificação',    remark = 'Notificação'         WHERE dict_code = 14;
UPDATE sys_dict_data SET dict_label = 'Aviso',          remark = 'Aviso'               WHERE dict_code = 15;
UPDATE sys_dict_data SET dict_label = 'Ativo',          remark = 'Status ativo'        WHERE dict_code = 16;
UPDATE sys_dict_data SET dict_label = 'Fechado',        remark = 'Status fechado'      WHERE dict_code = 17;
UPDATE sys_dict_data SET dict_label = 'Outro',          remark = 'Outra operação'      WHERE dict_code = 18;
UPDATE sys_dict_data SET dict_label = 'Adicionar',      remark = 'Operação de inclusão' WHERE dict_code = 19;
UPDATE sys_dict_data SET dict_label = 'Editar',         remark = 'Operação de alteração' WHERE dict_code = 20;
UPDATE sys_dict_data SET dict_label = 'Excluir',        remark = 'Operação de exclusão' WHERE dict_code = 21;
UPDATE sys_dict_data SET dict_label = 'Autorizar',      remark = 'Operação de autorização' WHERE dict_code = 22;
UPDATE sys_dict_data SET dict_label = 'Exportar',       remark = 'Operação de exportação' WHERE dict_code = 23;
UPDATE sys_dict_data SET dict_label = 'Importar',       remark = 'Operação de importação' WHERE dict_code = 24;
UPDATE sys_dict_data SET dict_label = 'Encerrar',       remark = 'Operação de encerramento' WHERE dict_code = 25;
UPDATE sys_dict_data SET dict_label = 'Gerar código',   remark = 'Operação de geração de código' WHERE dict_code = 26;
UPDATE sys_dict_data SET dict_label = 'Limpar dados',   remark = 'Operação de limpeza' WHERE dict_code = 27;
UPDATE sys_dict_data SET dict_label = 'Sucesso',        remark = 'Status ativo'        WHERE dict_code = 28;
UPDATE sys_dict_data SET dict_label = 'Falha',          remark = 'Status inativo'      WHERE dict_code = 29;

-- System parameters.
UPDATE sys_config SET config_name = 'Página principal - nome do tema padrão',
       remark = 'Tema azul skin-blue, verde skin-green, roxo skin-purple, vermelho skin-red, amarelo skin-yellow'
       WHERE config_id = 1;
UPDATE sys_config SET config_name = 'Usuários - senha inicial da conta',
       remark = 'Senha inicial 123456'
       WHERE config_id = 2;
UPDATE sys_config SET config_name = 'Página principal - tema da barra lateral',
       remark = 'Tema escuro theme-dark, tema claro theme-light'
       WHERE config_id = 3;
UPDATE sys_config SET config_name = 'Auto-atendimento - permitir cadastro de usuários',
       remark = 'Habilita o cadastro de usuários (true habilita, false desabilita)'
       WHERE config_id = 4;
UPDATE sys_config SET config_name = 'Acesso de usuários - lista de bloqueio',
       remark = 'Lista de IPs bloqueados para acesso, separados por ; (aceita * e faixas)'
       WHERE config_id = 5;
UPDATE sys_config SET config_name = 'Usuários - política para a senha inicial',
       remark = '0: sem avisos; 1: avisa o usuário que ainda usa a senha inicial ao entrar'
       WHERE config_id = 6;
UPDATE sys_config SET config_name = 'Usuários - validade da senha',
       remark = 'Validade da senha em dias (0 sem limite; se alterado, use um inteiro maior que 0 e menor que 365)'
       WHERE config_id = 7;
UPDATE sys_config SET config_name = 'Usuários - caracteres aceitos na senha',
       remark = '0 quaisquer caracteres, 1 apenas números, 2 apenas letras, 3 letras e números, 4 letras, números e caracteres especiais (~!@#$%^&*()-=_+)'
       WHERE config_id = 8;

-- Demo scheduled jobs (the invoke targets are code identifiers and stay as they are).
UPDATE sys_job SET job_name = 'Sistema padrão (sem parâmetros)'    WHERE job_id = 1;
UPDATE sys_job SET job_name = 'Sistema padrão (com parâmetros)'    WHERE job_id = 2;
UPDATE sys_job SET job_name = 'Sistema padrão (vários parâmetros)' WHERE job_id = 3;

-- Demo notices: all three are vendor copy (the third one is the project's own introduction).
UPDATE sys_notice SET notice_title = 'Boas-vindas ao sistema', notice_content = 'Este painel está pronto para uso.'
       WHERE notice_id = 1;
UPDATE sys_notice SET notice_title = 'Manutenção programada', notice_content = 'O sistema passará por manutenção programada. Salve seu trabalho e evite operações neste período.'
       WHERE notice_id = 2;
UPDATE sys_notice SET notice_title = 'Bem-vindo ao painel', notice_content = 'Use o menu à esquerda para administrar usuários, perfis, departamentos, dicionários, parâmetros e demais recursos do sistema.'
       WHERE notice_id = 3;

-- Menu remarks (shown in the menu list).
UPDATE sys_menu SET remark = 'Diretório de administração'    WHERE menu_id = 1;
UPDATE sys_menu SET remark = 'Diretório de monitoramento'    WHERE menu_id = 2;
UPDATE sys_menu SET remark = 'Diretório de ferramentas'      WHERE menu_id = 3;
UPDATE sys_menu SET remark = 'Menu de usuários'              WHERE menu_id = 100;
UPDATE sys_menu SET remark = 'Menu de perfis'                WHERE menu_id = 101;
UPDATE sys_menu SET remark = 'Menu de menus'                 WHERE menu_id = 102;
UPDATE sys_menu SET remark = 'Menu de departamentos'         WHERE menu_id = 103;
UPDATE sys_menu SET remark = 'Menu de cargos'                WHERE menu_id = 104;
UPDATE sys_menu SET remark = 'Menu de dicionários'           WHERE menu_id = 105;
UPDATE sys_menu SET remark = 'Menu de parâmetros'            WHERE menu_id = 106;
UPDATE sys_menu SET remark = 'Menu de avisos'                WHERE menu_id = 107;
UPDATE sys_menu SET remark = 'Menu de logs'                  WHERE menu_id = 108;
UPDATE sys_menu SET remark = 'Menu de usuários online'       WHERE menu_id = 109;
UPDATE sys_menu SET remark = 'Menu de tarefas agendadas'     WHERE menu_id = 110;
UPDATE sys_menu SET remark = 'Menu de controle de tráfego'   WHERE menu_id = 111;
UPDATE sys_menu SET remark = 'Menu de governança de serviços' WHERE menu_id = 112;
UPDATE sys_menu SET remark = 'Menu de monitoramento de serviços' WHERE menu_id = 113;
UPDATE sys_menu SET remark = 'Menu do construtor de formulários' WHERE menu_id = 114;
UPDATE sys_menu SET remark = 'Menu do gerador de código'     WHERE menu_id = 115;
UPDATE sys_menu SET remark = 'Menu da API do sistema'        WHERE menu_id = 116;
UPDATE sys_menu SET remark = 'Menu de log de operações'      WHERE menu_id = 500;
UPDATE sys_menu SET remark = 'Menu de log de acessos'        WHERE menu_id = 501;
