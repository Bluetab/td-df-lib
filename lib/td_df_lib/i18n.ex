defmodule TdDfLib.I18n do
  @moduledoc """
  Manages content formatting
  """

  alias TdCache.I18nCache
  alias TdDfLib.Format

  @translatable_widgets ~w(markdown string textarea)

  def get_translatable_fields(template) do
    template
    |> Map.get(:content)
    |> Format.flatten_content_fields()
    |> Enum.filter(&(&1["widget"] in @translatable_widgets))
    |> Enum.map(& &1["name"])
  end

  def is_translatable_field?(template = %{}, field) when is_binary(field) do
    template
    |> Map.get(:content)
    |> Format.flatten_content_fields()
    |> Enum.any?(fn field_map ->
      field_map["name"] == field and field_map["widget"] in @translatable_widgets
    end)
  end

  def is_translatable_field?(field) when is_map(field),
    do: field["widget"] in @translatable_widgets

  def get_field_locale(field, opts \\ []) do
    active_locales = Keyword.get(opts, :active_locales, I18nCache.get_active_locales!())

    case Regex.run(~r/^(.+)_([a-z]{2})$/, field) do
      [_, base_field, locale] ->
        if locale in active_locales do
          {base_field, locale}
        else
          {field, nil}
        end

      _ ->
        {field, nil}
    end
  end

  def split_i18n_params(params, default_lang, active_locales \\ nil) do
    active_locales = active_locales || I18nCache.get_active_locales!()
    opts = [active_locales: active_locales]

    Enum.reduce(
      params,
      [params: %{}, i18n_params: %{}],
      fn {key, value}, [params: params, i18n_params: i18n_params] ->
        case get_field_locale(key, opts) do
          {field, nil} ->
            [
              params: Map.put(params, field, value),
              i18n_params: i18n_params
            ]

          {field, locale} when locale != default_lang ->
            field_i18n_params = Map.get(i18n_params, locale, %{})

            [
              params: params,
              i18n_params:
                Map.put(
                  i18n_params,
                  locale,
                  Map.put(field_i18n_params, field, value)
                )
            ]

          {field, _locale} ->
            [
              params: Map.put(params, field, value),
              i18n_params: i18n_params
            ]
        end
      end
    )
  end

  def format_content_values(content, default_lang, active_locales) do
    i18n_locales = active_locales -- [default_lang]
    initial_i18n_content = Map.new(i18n_locales, fn locale -> {locale, %{"content" => %{}}} end)
    opts = [active_locales: active_locales]

    Enum.reduce(
      content,
      [content: %{}, i18n_content: initial_i18n_content],
      fn {key, value}, [content: content, i18n_content: i18n_content] ->
        case get_field_locale(key, opts) do
          {field, nil} ->
            [
              content: Map.put(content, field, value),
              i18n_content: i18n_content
            ]

          {field, locale} when locale != default_lang ->
            [
              content: content,
              i18n_content: put_in(i18n_content, [locale, "content", field], value)
            ]

          {field, _locale} ->
            [
              content: Map.put(content, field, value),
              i18n_content: i18n_content
            ]
        end
      end
    )
  end

  def process_i18n_fields(data, ctx) do
    default_lang = Map.get(ctx, :default_lang, "en")
    active_locales = Map.get(ctx, :active_locales, ["en"])

    base_params = Map.drop(data, ["_sheet", "_row_number", "df_content"])

    [params: clean_params, i18n_params: i18n_params] =
      split_i18n_params(base_params, default_lang, active_locales)

    df_content = Map.get(data, "df_content", %{})

    [content: clean_content, i18n_content: i18n_content_from_df] =
      format_content_values(df_content, default_lang, active_locales)

    i18n_content =
      Enum.reduce(i18n_params, i18n_content_from_df, fn {locale, locale_params}, acc ->
        locale_content = Map.get(acc, locale, %{})
        merged = Map.merge(locale_content, locale_params)
        Map.put(acc, locale, merged)
      end)

    processed_data =
      clean_params
      |> Map.put("_sheet", Map.get(data, "_sheet"))
      |> Map.put("_row_number", Map.get(data, "_row_number"))
      |> Map.put("df_content", clean_content)

    {processed_data, i18n_content}
  end
end
