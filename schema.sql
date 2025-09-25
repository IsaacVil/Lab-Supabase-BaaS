--====================================DDL====================================
-- Dominios
create table if not exists public.countries (
    code text primary key,
    name text not null
);

create table if not exists public.categories (
    id bigint generated always as identity primary key,
    name text not null unique
);
-- Comercial
create table if not exists public.products (
    id bigint generated always as identity primary key,
    name text not null,
    category_id bigint not null references public.categories(id),
    unit_price numeric(12,2) not null check (unit_price >= 0),
    created_at timestamptz default now()
);

create table if not exists public.customers (
    id bigint generated always as identity primary key,
    name text not null,
    email text,
    country_code text not null references public.countries(code),
    created_at timestamptz default now()
);

create table if not exists public.invoices (
    id bigint generated always as identity primary key,
    customer_id bigint not null references public.customers(id),
    invoice_date date not null default current_date,
    total_amount numeric(14,2) not null default 0,
    created_at timestamptz default now()
);

create table if not exists public.invoice_lines (
    id bigint generated always as identity primary key,
    invoice_id bigint not null references public.invoices(id) on delete cascade,
    product_id bigint not null references public.products(id),
    quantity numeric(12,2) not null check (quantity > 0),
    unit_price numeric(12,2) not null check (unit_price >= 0),
    line_total numeric(14,2) not null check (line_total >= 0)
);
-- Tablas de Autorización (para RLS)
create table if not exists public.user_allowed_country (
    user_id uuid not null references auth.users(id),
    country_code text not null references public.countries(code),
    primary key (user_id, country_code)
);

create table if not exists public.user_allowed_category (
    user_id uuid not null references auth.users(id),
    category_id bigint not null references public.categories(id),
    primary key (user_id, category_id)
);
--====================================RLS====================================
alter table public.countries enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_lines enable row level security;
alter table public.user_allowed_country enable row level security;
alter table public.user_allowed_category enable row level security;

--Politicas por categoria (products)

create policy "products_by_user_category_select"
on public.products for select
to authenticated
using (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
));

create policy "products_by_user_category_insert"
on public.products for insert
to authenticated
with check (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
));

create policy "products_by_user_category_update"
on public.products for update
to authenticated
using (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
))
with check (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
));

create policy "products_by_user_category_delete"
on public.products for delete
to authenticated
using (exists (
 select 1 from public.user_allowed_category u
 where u.user_id = auth.uid() and u.category_id = products.category_id
));

--Politicas por pais (Customers)

create policy "customers_by_user_country_select"
on public.customers for select
to authenticated
using (exists (
 select 1 from public.user_allowed_country u
 where u.user_id = auth.uid() and u.country_code =
customers.country_code
));

create policy "customers_by_user_country_insert"
on public.customers for insert
to authenticated
with check (exists (
 select 1 from public.user_allowed_country u
 where u.user_id = auth.uid() and u.country_code =
customers.country_code
));

create policy "customers_by_user_country_update"
on public.customers for update
to authenticated
using (exists (
 select 1 from public.user_allowed_country u
 where u.user_id = auth.uid() and u.country_code =
customers.country_code
))
with check (exists (
 select 1 from public.user_allowed_country u
 where u.user_id = auth.uid() and u.country_code =
customers.country_code
));

create policy "customers_by_user_country_delete"
on public.customers for delete
to authenticated
using (exists (
 select 1 from public.user_allowed_country u
 where u.user_id = auth.uid() and u.country_code =
customers.country_code
));

--Políticas en invoices (por país del cliente)

create policy "invoices_by_user_country_select"
on public.invoices for select
to authenticated
using (exists (
 select 1
 from public.customers c
 join public.user_allowed_country u
 on u.country_code = c.country_code and u.user_id = auth.uid()
 where c.id = invoices.customer_id
));

create policy "invoices_by_user_country_insert"
on public.invoices for insert
to authenticated
with check (exists (
 select 1
 from public.customers c
 join public.user_allowed_country u
 on u.country_code = c.country_code and u.user_id = auth.uid()
 where c.id = invoices.customer_id
));

create policy "invoices_by_user_country_update"
on public.invoices for update
to authenticated
using (exists (
 select 1
 from public.customers c
 join public.user_allowed_country u
 on u.country_code = c.country_code and u.user_id = auth.uid()
 where c.id = invoices.customer_id
))
with check (exists (
 select 1
 from public.customers c
 join public.user_allowed_country u
 on u.country_code = c.country_code and u.user_id = auth.uid()
 where c.id = invoices.customer_id
));

create policy "invoices_by_user_country_delete"
on public.invoices for delete
to authenticated
using (exists (
 select 1
 from public.customers c
 join public.user_allowed_country u
 on u.country_code = c.country_code and u.user_id = auth.uid()
 where c.id = invoices.customer_id
));

--Políticas en invoice_lines (por país y categoría)

create policy "lines_by_country_and_category_select"
on public.invoice_lines for select
to authenticated
using (
 exists (
 select 1
 from public.invoices i
 join public.customers c on c.id = i.customer_id
 join public.user_allowed_country uc
 on uc.country_code = c.country_code and uc.user_id = auth.uid()
 where i.id = invoice_lines.invoice_id
 )
 and
 exists (
 select 1
 from public.products p
 join public.user_allowed_category ug
 on ug.category_id = p.category_id and ug.user_id = auth.uid()
 where p.id = invoice_lines.product_id
 )
);

create policy "lines_by_country_and_category_cud"
on public.invoice_lines for all
to authenticated
using (
 exists (
 select 1
 from public.invoices i
 join public.customers c on c.id = i.customer_id
 join public.user_allowed_country uc
 on uc.country_code = c.country_code and uc.user_id = auth.uid()
 where i.id = invoice_lines.invoice_id
 )
 and
 exists (
 select 1
 from public.products p
 join public.user_allowed_category ug
 on ug.category_id = p.category_id and ug.user_id = auth.uid()
 where p.id = invoice_lines.product_id
 )
)
with check (
 exists (
 select 1
 from public.invoices i
 join public.customers c on c.id = i.customer_id
 join public.user_allowed_country uc
 on uc.country_code = c.country_code and uc.user_id = auth.uid()
 where i.id = invoice_lines.invoice_id
 )
 and
 exists (
 select 1
 from public.products p
 join public.user_allowed_category ug
 on ug.category_id = p.category_id and ug.user_id = auth.uid()
 where p.id = invoice_lines.product_id
 )
);