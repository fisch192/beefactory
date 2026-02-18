import de from '../i18n/de.json';
import it from '../i18n/it.json';

const translations: Record<string, Record<string, string>> = { de, it };

export type Lang = 'de' | 'it';

export function t(key: string, lang: Lang): string {
  return translations[lang]?.[key] ?? key;
}

export function getLangFromUrl(url: URL): Lang {
  const [, lang] = url.pathname.split('/');
  if (lang === 'it') return 'it';
  return 'de';
}

export function getAlternateLang(lang: Lang): Lang {
  return lang === 'de' ? 'it' : 'de';
}

export function getLocalizedPath(path: string, lang: Lang): string {
  // Replace /de/ or /it/ prefix
  return path.replace(/^\/(de|it)\//, `/${lang}/`);
}
